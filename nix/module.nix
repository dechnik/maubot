{ lib
, pkgs
, config
, ...
}:

let
  cfg = config.services.maubot;

  maubotCfg = {
  };
  format = pkgs.formats.yaml { };
  configYaml = format.generate "config.yaml" maubotCfg;
in
{
  options.services.maubot = {
    enable = lib.mkEnableOption "maubot";
    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.system}.default;
      description = "The package implementing maubot";
    };
    username = mkOption { type = types.str; };
    homeserver = mkOption { type = types.str; };
    publicUrl = mkOption { type = types.str; };
    secretYAML = mkOption { type = types.path; };
    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/maubot";
    };
  };
}
