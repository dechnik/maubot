self: { lib
, pkgs
, config
, ...
}:
with lib;
let
  cfg = config.services.maubot-rss;

  maubotCfg = {
    user = {
      credentials = {
        id = cfg.userName;
        homeserver = cfg.homeServer;
      };
      sync = true;
      autojoin = true;
      displayname = "Rss [dechnik.net]";
      ignore_initial_sync = true;
      ignore_first_sync = true;
    };
    database = "sqlite:///rss.db";
    server = {
      hostname = cfg.serverHostname;
      port = cfg.serverPort;
      public_url = cfg.publicUrl;
      base_path = "/_matrix/maubot/plugin/rss";
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

    plugin_config = {
        update_interval = cfg.updateInterval;
        max_backoff = 7200;
        spam_sleep = 2;
        command_prefix = "rss";
        notification_template = cfg.notificationTemplate;
        admins = cfg.adminUsers;
    };
  };

  format = pkgs.formats.yaml { };
  configYaml = format.generate "config.yaml" maubotCfg;
in
{
  options.services.maubot-rss = {
    enable = mkEnableOption "Rss maubot";
    package = mkOption {
      type = types.package;
      default = self.packages.${pkgs.system}.default;
      description = "The package implementing maubot";
    };
    notificationTemplate = mkOption {
      type = types.str;
      default = "New post in $feed_title: [$title]($link)";
    };
    updateInterval = mkOption {
      type = types.int;
      default = 60;
    };
    adminUsers = mkOption {
      type = types.list;
      default = [ "@user:example.com" ];
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
      default = 8823;
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
      default = "/var/lib/maubot-rss";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.maubot-rss = {
      description = "Rss Maubot";
      after = [
        "matrix-synapse.target"
      ];
      wantedBy = [ "multi-user.target" ];
      preStart = ''
        ${pkgs.git}/bin/git clone https://github.com/maubot/rss src
        cp -r src/* .
        rm -rf src
        ${pkgs.yq-go}/bin/yq ea '. as $item ireduce ({}; . * $item )' \
          ${configYaml} ${cfg.secretYAML} > config.yaml
      '';
      serviceConfig = {
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${cfg.package}/bin/standalone";
        Restart = "on-failure";
        User = "maubot-rss";
        Group = "maubot-rss";
      };
    };
    users = {
      users.maubot-rss = {
        group = "maubot-rss";
        isSystemUser = true;
        home = cfg.dataDir;
        createHome = true;
      };
      groups.maubot-rss = { };
    };
  };
}
