{
  description = "Maubot";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor = nixpkgs.legacyPackages;
    in
    rec {
      nixosModules = {
          default = import nix/module.nix self;
          alert = import nix/module-alert.nix self;
      };

      packages = forAllSystems (system: {
        default = pkgsFor.${system}.callPackage nix/default.nix { inherit nixpkgs system; };
      });
      hydraJobs = packages;
    };
}
