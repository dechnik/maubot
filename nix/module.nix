self: { lib
, self
, pkgs
, config
, ...
}:
with lib;
let
  cfg = config.services.maubot;

  maubotCfg = {
    database = "sqlite:///maubot.db";
    server = {
      hostname = cfg.serverHostname;
      port = cfg.serverPort;
      ui_base_path = "/_matrix/maubot";
      plugin_base_path = "/_matrix/maubot/plugin/";
      public_url = cfg.publicUrl;
    };
    api_features = {
      login = true;
      plugin = true;
      plugin_upload = true;
      instance = true;
      instance_database = true;
      client = true;
      client_proxy = true;
      client_auth = true;
      dev_open = true;
      log = true;
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
  options.services.maubot = {
    enable = mkEnableOption "maubot";
    package = mkOption {
      type = types.package;
      default = self.packages.${pkgs.system}.default;
      description = "The package implementing maubot";
    };
    serverHostname = mkOption {
      type = types.str;
      default = "127.0.0.1";
    };
    serverPort = mkOption {
      type = types.str;
      default = 29316;
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
      default = "/var/lib/maubot";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.maubot = {
      description = "Maubot";
      after = [
        "matrix-synapse.target"
      ];
      wantedBy = [ "multi-user.target" ];
      preStart = ''
        ${pkgs.yq-go}/bin/yq ea '. as $item ireduce ({}; . * $item )' \
          ${configYaml} ${cfg.secretYAML} > config.yaml
      '';
      serviceConfig = {
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${maubot}/bin/maubot";
        Restart = "on-failure";
        User = "maubot";
        Group = "maubot";
      };
    };
    users = {
      users.maubot = {
        group = "maubot";
        isSystemUser = true;
        home = cfg.dataDir;
        createHome = true;
      };
      groups.maubot = { };
    };
  };
}
