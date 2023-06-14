self: { lib
, pkgs
, config
, ...
}:
with lib;
let
  cfg = config.services.maubot-alert;

  maubotCfg = {
    user = {
      credentials = {
        id = cfg.userName;
        homeserver = cfg.homeServer;
      };
      sync = true;
      autojoin = true;
      displayname = "Alert [dechnik.net]";
      ignore_initial_sync = true;
      ignore_first_sync = true;
    };
    database = "sqlite:///alert.db";
    server = {
      hostname = cfg.serverHostname;
      port = cfg.serverPort;
      public_url = cfg.publicUrl;
    };
    logging = {
      version = 1;
      formatters.journal_fmt.format = "%(name)s: %(message)s";
      handlers.journal = {
        class = "systemd.journal.JournalHandler";
        formatter = "journal_fmt";
      };
      loggers = {
        maubot.level = "DEBUG";
        mau.level = "DEBUG";
        aiohttp.level = "INFO";
      };
      root = {
        level = "DEBUG";
        handlers = [ "journal" ];
      };
    };
  };
  format = pkgs.formats.yaml { };
  configYaml = format.generate "config.yaml" maubotCfg;
in
{
  options.services.maubot-alert = {
    enable = mkEnableOption "Alert maubot";
    package = mkOption {
      type = types.package;
      default = self.packages.${pkgs.system}.default;
      description = "The package implementing maubot";
    };
    userName = mkOption {
      type = types.str;
    };
    homeServer = mkOption {
      type = types.str;
    };
    serverHostname = mkOption {
      type = types.str;
      default = "127.0.0.1";
    };
    serverPort = mkOption {
      type = types.int;
      default = 8820;
    };
    publicUrl = mkOption {
      type = types.str;
      default = "https://example.com";
    };
    secretYAML = mkOption {
      type = types.path;
    };
    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/maubot-alert";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.maubot-alert = {
      description = "Alert Maubot";
      after = [
        "matrix-synapse.target"
      ];
      wantedBy = [ "multi-user.target" ];
      preStart = ''
        ${pkgs.git}/bin/git clone https://github.com/moan0s/alertbot.git src
        cp -r src/* .
        rm -rf src
        ${pkgs.yq-go}/bin/yq ea '. as $item ireduce ({}; . * $item )' \
          ${configYaml} ${cfg.secretYAML} > config.yaml
      '';
      serviceConfig = {
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${cfg.package}/bin/standalone";
        Restart = "on-failure";
        User = "maubot-alert";
        Group = "maubot-alert";
      };
    };
    users = {
      users.maubot-alert = {
        group = "maubot-alert";
        isSystemUser = true;
        home = cfg.dataDir;
        createHome = true;
      };
      groups.maubot-alert = { };
    };
  };
}
