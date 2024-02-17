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
      pkgs = ({ pkgs, ... }: {
        nixpkgs.overlays = [
          # ... stuff here ...
        ];
      });
      flakesOverlay = final: prev: {
        agenix = agenix.packages.${prev.system}.default;
      };
    in
    {
      nixosConfigurations = {
        erms = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = attrs // { nixpkgs = pkgs; };
          modules = [
            ({ config, pkgs, ... }: { nixpkgs.overlays = [ flakesOverlay ]; })
            agenix.nixosModules.default
            home-manager.nixosModules.home-manager
            ./machines/erms
          ];
        };

        kashenblade = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = attrs;
          modules = [
            agenix.nixosModules.default
            home-manager.nixosModules.home-manager
            ./machines/kashenblade
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
    };
}
