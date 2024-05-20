{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    gimp-nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
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
      url = "github:zebreus/gnome-online-accounts-config";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wallpaper = {
      url = "github:zebreus/nixos-dark-wallpaper";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    besserestrichliste = {
      url = "github:zebreus/besserestrichliste";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, gimp-nixpkgs, home-manager, disko, agenix, simple-nix-mailserver, gnome-online-accounts-config, nixos-wallpaper, besserestrichliste, ... }@attrs:
    let

      overlays = [
        (final: prev:
          let
            gimp-pkgs = import gimp-nixpkgs {
              system = prev.system;
              # gimp with plugins needs an ancient python version
              config.permittedInsecurePackages = [
                "python-2.7.18.7-env"
                "python-2.7.18.7"
              ];
              overlays = [
                (final: prev: {
                  gimp = prev.gimp.override {
                    withPython = true;
                  };
                })
              ];
            };
          in
          {
            agenix = agenix.packages.${prev.system}.default;
            nixos-wallpaper = nixos-wallpaper.packages.${prev.system}.default;

            gimp-with-plugins = gimp-pkgs.gimp-with-plugins;
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
            workstation.enable = true;
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
            trustedPorts = [ 9100 ];
            monitoring.enable = true;
            matrixServer = {
              enable = true;
              baseDomain = "zebre.us";
              certEmail = "lennarteichhorn@googlemail.com";
            };
          };
          kappril = {
            name = "kappril";
            address = 3;
            wireguardPublicKey = publicKeys.kappril_wireguard;
            publicPorts = [ 22 ];
            sshPublicKey = publicKeys.kappril;
            backupHost.enable = true;
          };
          # Janeks laptop
          janek = {
            name = "janek";
            address = 4;
            wireguardPublicKey = publicKeys.janek_wireguard;
            extraBorgRepos = [
              { name = "janek"; size = "2T"; }
            ];
          };
          # Janeks server
          janek-proxmox = {
            name = "janek-proxmox";
            address = 5;
            wireguardPublicKey = publicKeys.janek-proxmox_wireguard;
            extraBorgRepos = [
              { name = "janek-proxmox"; size = "2T"; }
            ];
          };
          # Janeks backup server
          janek-backup = {
            name = "janek-backup";
            address = 6;
            wireguardPublicKey = publicKeys.janek-backup_wireguard;
            public = true;
            backupHost = {
              enable = true;
              storagePath = "/backups/lennart";
            };
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
            mailServer = {
              enable = true;
              baseDomain = "zebre.us";
              certEmail = "lennarteichhorn@googlemail.com";
            };
          };

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
            workstation.enable = true;
          };
          # Leon (friend of basilikum) laptop
          leon = {
            name = "leon";
            address = 10;
            wireguardPublicKey = publicKeys.leon_wireguard;
            extraBorgRepos = [
              { name = "leon"; size = "2T"; }
            ];
          };
          # MARKER_MACHINE_CONFIGURATIONS
        };
      };
    in
    {
      nixosConfigurations =
        let
          commonModules = [
            agenix.nixosModules.default
            overlayNixpkgs
            informationAboutOtherMachines
            home-manager.nixosModules.home-manager
            simple-nix-mailserver.nixosModules.default
            gnome-online-accounts-config.nixosModules.default
            besserestrichliste.nixosModules.aarch64-linux.default
          ];
        in
        {
          erms = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              ./machines/erms
            ] ++ commonModules;
          };

          kashenblade = nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            modules = [
              ./machines/kashenblade
            ] ++ commonModules;
          };

          kappril = nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            modules = [
              ./machines/kappril
            ] ++ commonModules;
          };

          sempriaq = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              ./machines/sempriaq
            ] ++ commonModules;
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
              # besserestrichliste.nixosModules.aarch64-linux.default
              ./machines/hetzner-template
            ];
          };

          blanderdash = nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            modules = [
              ./machines/blanderdash
            ] ++ commonModules;
          };
          prandtl = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              disko.nixosModules.disko
              ./machines/prandtl
            ] ++ commonModules;
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

      packages.x86_64-linux = {
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

        generate-docs = pkgs.callPackage ./scripts/generate-docs.nix { };
        generate-installer = pkgs.callPackage ./scripts/generate-installer.nix { };
      };

      formatter.x86_64-linux = pkgs.nixpkgs-fmt;
    };
}

