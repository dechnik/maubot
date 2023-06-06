{ lib
, pkgs
, config
, ...
}:

let
  cfg = config.services.maubot;

  format = pkgs.formats.yaml { };
  configFile = format.generate "config.yaml" cfg.settings;
in
{
  options.services.maubot = {
    enable = lib.mkEnableOption "maubot";
    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.system}.default;
      description = "The package implementing maubot";
    };
    settings = mkOption {
      description = mdDoc ''
      '';
      default = { };
      example = ''
        {
        }
      '';
      type = types.submodule {
        freeformType = format.type;
        options = {
          theme = mkOption {
            type = types.enum [ "light" "dark" "grey" "auto" ];
            default = "light";
            example = "dark";
            description = mdDoc "The theme to display.";
          };
        };
      };
    };
  };
}
