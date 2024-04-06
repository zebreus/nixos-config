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
      overlayNixpkgs = { config, pkgs, ... }: {
        nixpkgs.overlays = overlays;
      };

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
            vpnHub.enable = true;
            sshPublicKey = publicKeys.kashenblade;
            authoritativeDns.enable = true;
            authoritativeDns.name = "ns1";
            publicPorts = [ 53 ];
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
            authoritativeDns.enable = true;
            authoritativeDns.name = "ns3";
            publicPorts = [ 53 ];
            staticIp4 = "192.227.228.220";
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
            authoritativeDns.enable = true;
            authoritativeDns.primary = true;
            authoritativeDns.name = "ns2";
            publicPorts = [ 53 ];
            staticIp4 = "49.13.8.171";
            staticIp6 = "2a01:4f8:c013:29b1::1";
          };
          prandtl = {
            name = "prandtl";
            address = 9;
            wireguardPublicKey = publicKeys.prandtl_wireguard;
            trusted = true;
            sshPublicKey = publicKeys.prandtl;
          };
          # MARKER_MACHINE_CONFIGURATIONS
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
          prandtl = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = attrs;
            modules = [
              agenix.nixosModules.default
              disko.nixosModules.disko
              overlayNixpkgs
              informationAboutOtherMachines
              home-manager.nixosModules.home-manager
              simple-nix-mailserver.nixosModules.default
              gnome-online-accounts-config.nixosModules.default
              ./machines/prandtl
            ];
          };
          # MARKER_NIXOS_CONFIGURATIONS

          # ISO image for a up-to-date NixOS installer
          installer = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
              ({ pkgs, ... }: {
                networking.wireless.enable = false;
                networking.networkmanager.enable = true;
                environment.systemPackages = [ pkgs.rsync pkgs.git ];
                users.users.root.password = nixpkgs.lib.mkForce "54321";
                users.users.root.initialHashedPassword = nixpkgs.lib.mkForce null;
                users.users.root.openssh.authorizedKeys.keys = [ publicKeys.lennart ];
                boot.kernelPackages = pkgs.linuxPackages_latest;
                boot.supportedFilesystems.bcachefs = nixpkgs.lib.mkForce true;
                boot.supportedFilesystems.zfs = nixpkgs.lib.mkForce false;
              })
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
      setup-host = pkgs.callPackage ./scripts/setup-host.nix { };
      add-workstation = pkgs.callPackage ./scripts/add-workstation.nix { };

      generate-docs =
        let
          optionsDoc = pkgs.nixosOptionsDoc {
            inherit ((nixpkgs.lib.evalModules {
              modules = [
                informationAboutOtherMachines
                ./modules
                {
                  documentation.nixos.options.warningsAreEsrrors = false;
                }
              ];
              check = false;

            })) options;
            transformOptions = opt: opt // {
              # Clean up declaration sites to not refer to the NixOS source tree.
              declarations = map
                (decl:
                  let subpath = nixpkgs.lib.removePrefix "/" (nixpkgs.lib.removePrefix (toString ./.) (toString decl));
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
      generate-installer = pkgs.writeScriptBin "generate-installer" ''
        #!${pkgs.bash}/bin/bash

        RESULT_PATH=$(nix build .#nixosConfigurations.installer.config.system.build.isoImage --print-out-paths)
        echo $RESULT_PATH
        ln -s $RESULT_PATH/iso/* ./installer.iso
      '';

      # Raspi SD card image
      image.kappril = nixosConfigurations.kappril.config.system.build.sdImage;

      formatter.x86_64-linux = pkgs.nixpkgs-fmt;
    };
}

