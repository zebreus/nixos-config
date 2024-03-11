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
    simple-nix-mailserver = {
      url = "gitlab:GaetanLepage/nixos-mailserver";
      # TODO: Make the mailserver follow the main nixpkgs, once it supports current nixpkgs.
      # inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, disko, agenix, simple-nix-mailserver, ... }@attrs:
    let
      # TODO: Remove this once the mailserver supports current nixpkgs.
      nixpkgsThatAreWorkingWithTheMailserver = simple-nix-mailserver.inputs.nixpkgs;

      overlays = [
        (final: prev: {
          agenix = agenix.packages.${prev.system}.default;
        })
      ];
      pkgs = import nixpkgs {
        inherit overlays;
        system = "x86_64-linux";
      };
      publicKeys = import secrets/public-keys.nix;

      # Add some extra packages to nixpkgs
      overlayNixpkgs = ({ config, pkgs, ... }: {
        nixpkgs.overlays = overlays;
      });

      # Sets config options with information about other machines.
      # Only contains the information that is relevant for all machines.
      informationAboutOtherMachines = {
        imports = [
          modules/machines.nix
        ];
        machines = {
          erms = {
            name = "erms";
            address = 1;
            wireguardPublicKey = publicKeys.erms_wireguard;
            trusted = true;
            sshPublicKey = publicKeys.erms;
          };
          kashenblade = {
            name = "kashenblade";
            address = 2;
            wireguardPublicKey = publicKeys.kashenblade_wireguard;
            staticIp4 = "167.235.154.30";
            staticIp6 = "2a01:4f8:c0c:d91f::1";
            sshPublicKey = publicKeys.kashenblade;
          };
          kappril = {
            name = "kappril";
            address = 3;
            wireguardPublicKey = publicKeys.kappril_wireguard;
            public = true;
            sshPublicKey = publicKeys.kappril;
          };
          # Janeks laptop
          janek = {
            name = "janek";
            address = 4;
            wireguardPublicKey = publicKeys.janek_wireguard;
          };
          # Janeks server
          janek-proxmox = {
            name = "janek-proxmox";
            address = 5;
            wireguardPublicKey = publicKeys.janek-proxmox_wireguard;
          };
          # Janeks backup server
          janek-backup = {
            name = "janek-backup";
            address = 6;
            wireguardPublicKey = publicKeys.janek-backup_wireguard;
            public = true;
          };
          sempriaq = {
            name = "sempriaq";
            address = 7;
            wireguardPublicKey = publicKeys.sempriaq_wireguard;
            sshPublicKey = publicKeys.sempriaq;
            # staticIp4 = "192.227.228.220";
          };
        };
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
              informationAboutOtherMachines
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
              informationAboutOtherMachines
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
              informationAboutOtherMachines
              home-manager.nixosModules.home-manager
              agenix.nixosModules.default
              ./machines/kappril
            ];
          };

          sempriaq = nixpkgsThatAreWorkingWithTheMailserver.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = attrs;
            modules = [
              overlayNixpkgs
              informationAboutOtherMachines
              home-manager.nixosModules.home-manager
              agenix.nixosModules.default
              simple-nix-mailserver.nixosModules.default
              ./machines/sempriaq
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
      gen-borg-keys = pkgs.callPackage ./scripts/gen-borg-keys.nix { };
      gen-vpn-mail-secrets = pkgs.callPackage ./scripts/gen-vpn-mail-secrets.nix { };
      deploy-hosts = pkgs.callPackage ./scripts/deploy-hosts.nix { };

      # Raspi SD card image
      image.kappril = nixosConfigurations.kappril.config.system.build.sdImage;
    };
}
