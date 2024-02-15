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
  };

  outputs = { self, nixpkgs, home-manager, disko, ... }@attrs: {
    nixosConfigurations = {
      erms = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs;
        modules = [
          home-manager.nixosModules.home-manager
          ./machines/erms
        ];
      };

      kashenblade = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = attrs;
        modules = [
          home-manager.nixosModules.home-manager
          ./machines/kashenblade
        ];
      };

      hetzner-template = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        # specialArgs = attrs;
        modules = [
          disko.nixosModules.disko
          # home-manager.nixosModules.home-manager
          ./machines/hetzner-template
        ];
      };
    };
  };
}
