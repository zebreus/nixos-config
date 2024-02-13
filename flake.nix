{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }@attrs: {
    nixosConfigurations = {
      t15g = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs;
        modules = [
          ./machines/t15g
        ];
      };
    };
  };
}
