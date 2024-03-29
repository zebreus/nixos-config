{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:zebreus/home-manager?ref=init-secret-service";
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
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gnome-online-accounts-config = {
      # url = "/home/lennart/Documents/gnome-online-accounts-config";
      url = "github:zebreus/gnome-online-accounts-config";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, disko, agenix, simple-nix-mailserver, gnome-online-accounts-config, ... }@attrs:
    let

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
          modules/helpers/machines.nix
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
            publicPorts = [ 22 ];
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
            public = true;
          };
          # hetzner-template = {
          #   name = "hetzner-template";
          #   address = 99;
          #   wireguardPublicKey = publicKeys.hetzner-template_wireguard;
          #   sshPublicKey = publicKeys.hetzner-template;
          # };
          blanderdash = {
            name = "blanderdash";
            address = 8;
            wireguardPublicKey = publicKeys.blanderdash_wireguard;
            sshPublicKey = publicKeys.blanderdash;
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
              agenix.nixosModules.default
              overlayNixpkgs
              informationAboutOtherMachines
              home-manager.nixosModules.home-manager
              simple-nix-mailserver.nixosModules.default
              gnome-online-accounts-config.nixosModules.default
              ./machines/erms
            ];
          };

          kashenblade = nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            specialArgs = attrs;
            modules = [
              agenix.nixosModules.default
              overlayNixpkgs
              informationAboutOtherMachines
              home-manager.nixosModules.home-manager
              simple-nix-mailserver.nixosModules.default
              gnome-online-accounts-config.nixosModules.default
              ./machines/kashenblade
            ];
          };

          kappril = nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            specialArgs = attrs;
            modules = [
              agenix.nixosModules.default
              overlayNixpkgs
              informationAboutOtherMachines
              home-manager.nixosModules.home-manager
              simple-nix-mailserver.nixosModules.default
              gnome-online-accounts-config.nixosModules.default
              ./machines/kappril
            ];
          };

          sempriaq = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = attrs;
            modules = [
              agenix.nixosModules.default
              overlayNixpkgs
              informationAboutOtherMachines
              home-manager.nixosModules.home-manager
              simple-nix-mailserver.nixosModules.default
              gnome-online-accounts-config.nixosModules.default
              ./machines/sempriaq
            ];
          };

          hetzner-template = nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            modules = [
              disko.nixosModules.disko # Remove this after initial setup
              agenix.nixosModules.default
              # overlayNixpkgs
              # informationAboutOtherMachines
              # home-manager.nixosModules.home-manager
              # simple-nix-mailserver.nixosModules.default
              # gnome-online-accounts-config.nixosModules.default
              ./machines/hetzner-template
            ];
          };

          blanderdash = nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            modules = [
              agenix.nixosModules.default
              overlayNixpkgs
              informationAboutOtherMachines
              home-manager.nixosModules.home-manager
              simple-nix-mailserver.nixosModules.default
              gnome-online-accounts-config.nixosModules.default
              ./machines/blanderdash
            ];
          };
        };

      # Helper scripts
      gen-host-keys = pkgs.callPackage ./scripts/gen-host-keys.nix { };
      gen-wireguard-keys = pkgs.callPackage ./scripts/gen-wireguard-keys.nix { };
      gen-borg-keys = pkgs.callPackage ./scripts/gen-borg-keys.nix { };
      gen-vpn-mail-secrets = pkgs.callPackage ./scripts/gen-vpn-mail-secrets.nix { };
      gen-mail-dkim-keys = pkgs.callPackage ./scripts/gen-mail-dkim-keys.nix { };
      deploy-hosts = pkgs.callPackage ./scripts/deploy-hosts.nix { };
      fast-deploy = pkgs.callPackage ./scripts/fast-deploy.nix { };

      generate-docs =
        let
          optionsDoc = pkgs.nixosOptionsDoc {
            options = (nixpkgs.lib.evalModules {
              modules = [
                informationAboutOtherMachines
                ./modules
                {
                  documentation.nixos.options.warningsAreEsrrors = false;
                }
              ];
              check = false;

            }).options;
            transformOptions = opt: opt // {
              # Clean up declaration sites to not refer to the NixOS source tree.
              declarations = map
                (decl:
                  let subpath = nixpkgs.lib.removePrefix "/" (nixpkgs.lib.removePrefix (toString ./.) (toString (decl)));
                  in { url = subpath; name = subpath; })
                opt.declarations;
            };
          };
        in
        pkgs.writeScriptBin "generate-docs" ''
          #!${pkgs.bash}/bin/bash
          cp ${optionsDoc.optionsCommonMark} ./options.md
          chmod 644 ./options.md
        '';

      # Raspi SD card image
      image.kappril = nixosConfigurations.kappril.config.system.build.sdImage;
    };
}

