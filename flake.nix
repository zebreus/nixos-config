{
  inputs = {
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:Mic92/nixpkgs/matrix-synapse";
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
      # Prisma engines is currently not compatible with the rust version in the latest nixpkgs
      inputs.nixpkgs.follows = "gimp-nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs
    , gimp-nixpkgs
    , home-manager
    , disko
    , agenix
    , simple-nix-mailserver
    , gnome-online-accounts-config
    , nixos-wallpaper
    , besserestrichliste
    , lanzaboote
    , ...
    }:
    let
      overlays = [
        (
          final: prev:
            let
              gimp-pkgs = import gimp-nixpkgs {
                system = prev.system;
                # gimp with plugins needs an ancient python version
                config.permittedInsecurePackages = [
                  "python-2.7.18.7-env"
                  "python-2.7.18.7"
                ];
                overlays = [ (final: prev: { gimp = prev.gimp.override { withPython = true; }; }) ];
              };
            in
            {
              agenix = agenix.packages.${prev.system}.default;
              nixos-wallpaper = nixos-wallpaper.packages.${prev.system}.default;

              gimp-with-plugins = gimp-pkgs.gimp-with-plugins;
            }
        )
      ];
      pkgs = import nixpkgs {
        inherit overlays;
        system = "x86_64-linux";
      };
      publicKeys = import secrets/public-keys.nix;

      # Add some extra packages to nixpkgs
      overlayNixpkgs =
        { config, pkgs, ... }:
        {
          nixpkgs.overlays = overlays;
        };
    in
    {
      nixosConfigurations =
        let
          commonModules = [
            agenix.nixosModules.default
            overlayNixpkgs
            ./machines.nix
            home-manager.nixosModules.home-manager
            simple-nix-mailserver.nixosModules.default
            gnome-online-accounts-config.nixosModules.default
            besserestrichliste.nixosModules.aarch64-linux.default
          ];
        in
        {
          erms = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ ./machines/erms ] ++ commonModules;
          };

          kashenblade = nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            modules = [ ./machines/kashenblade ] ++ commonModules;
          };

          kappril = nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            modules = [ ./machines/kappril ] ++ commonModules;
          };

          sempriaq = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ ./machines/sempriaq ] ++ commonModules;
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
            modules = [ ./machines/blanderdash ] ++ commonModules;
          };
          prandtl = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              disko.nixosModules.disko
              lanzaboote.nixosModules.lanzaboote
              ./machines/prandtl
            ] ++ commonModules;
          };
          # MARKER_NIXOS_CONFIGURATIONS

          # ISO image for a up-to-date NixOS installer
          installer = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
              (
                { pkgs, ... }:
                {
                  networking.wireless.enable = false;
                  networking.networkmanager.enable = true;
                  environment.systemPackages = [
                    pkgs.rsync
                    pkgs.git
                  ];
                  users.users.root.password = nixpkgs.lib.mkForce "54321";
                  users.users.root.initialHashedPassword = nixpkgs.lib.mkForce null;
                  users.users.root.openssh.authorizedKeys.keys = [ publicKeys.lennart ];
                  boot.kernelPackages = pkgs.linuxPackages_latest;
                  boot.supportedFilesystems.bcachefs = nixpkgs.lib.mkForce true;
                  boot.supportedFilesystems.zfs = nixpkgs.lib.mkForce false;
                }
              )
            ];
          };
        };

      nixosModules = {
        vpn = { ... }: {
          imports = [
            ./machines.nix
            ./modules/vpn
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
        add-antibuilding-peer = pkgs.callPackage ./scripts/add-antibuilding-peer.nix { };
        add-workstation = pkgs.callPackage ./scripts/add-workstation.nix { };

        generate-docs = pkgs.callPackage ./scripts/generate-docs.nix { };
        generate-installer = pkgs.callPackage ./scripts/generate-installer.nix { };
        generate-raspi-image = pkgs.callPackage ./scripts/generate-raspi-image.nix { };
      };

      formatter.x86_64-linux = pkgs.nixpkgs-fmt;
    };
}
