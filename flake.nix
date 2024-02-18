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
      overlays = [
        (final: prev: {
          agenix = agenix.packages.${prev.system}.default;
        })
      ];

      overlayNixpkgs = ({ config, pkgs, ... }: {
        nixpkgs.overlays = overlays;
      });

      pkgs = import nixpkgs {
        inherit overlays;
        system = "x86_64-linux";
      };
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

      # Helper scripts
      gen-host-keys = pkgs.callPackage ./scripts/gen-host-keys.nix { };
      gen-wireguard-keys = pkgs.callPackage ./scripts/gen-wireguard-keys.nix { };

      # Raspi SD card image
      image.kappril = nixosConfigurations.kappril.config.system.build.sdImage;
    };
}
