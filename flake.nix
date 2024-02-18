{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, disko, agenix, ... }@attrs:
    let
      overlayNixpkgs = ({ config, pkgs, ... }: {
        nixpkgs.overlays = [
          (final: prev: {
            agenix = agenix.packages.${prev.system}.default;
          })
        ];
      });
    in
    rec   {
      nixosConfigurations =
        {
          erms = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = attrs;
            modules = [
              overlayNixpkgs
              agenix.nixosModules.default
              home-manager.nixosModules.home-manager
              ./machines/erms
            ];
          };

          kashenblade = nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            specialArgs = attrs;
            modules = [
              overlayNixpkgs
              agenix.nixosModules.default
              home-manager.nixosModules.home-manager
              ./machines/kashenblade
            ];
          };

          kappril = nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            specialArgs = attrs;
            modules = [
              overlayNixpkgs
              home-manager.nixosModules.home-manager
              agenix.nixosModules.default
              ./machines/kappril
            ];
          };

          hetzner-template = nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            # specialArgs = attrs;
            modules = [
              agenix.nixosModules.default
              disko.nixosModules.disko
              # home-manager.nixosModules.home-manager
              ./machines/hetzner-template
            ];
          };
        };

      image.kappril = nixosConfigurations.kappril.config.system.build.sdImage;
    };
}
