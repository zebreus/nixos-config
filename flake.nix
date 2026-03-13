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
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wallpaper = {
      url = "github:zebreus/nixos-dark-wallpaper";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    besserestrichliste = {
      url = "github:zebreus/besserestrichliste";
      # Prisma engines is currently not compatible with the rust version in the latest nixpkgs
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvirt = {
      url = "github:zebreus/NixVirt/dnsmasq-passthrough";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs
    , home-manager
    , disko
    , agenix
    , simple-nix-mailserver
    , nixos-wallpaper
    , besserestrichliste
    , lanzaboote
    , nixvirt
    , ...
    }:
    let
      overlays = [
        (
          final: prev:
            {
              agenix = agenix.packages.${prev.stdenv.hostPlatform.system}.default;
              nixos-wallpaper = nixos-wallpaper.packages.${prev.stdenv.hostPlatform.system}.default;
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

      lib = nixpkgs.lib.extend (
        self: super: { inherit (nixvirt.lib) domain pool network volume xml; }
      );
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
            besserestrichliste.nixosModules.aarch64-linux.default
          ];
        in
        {
          erms = lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ ./machines/erms ] ++ commonModules;
          };

          kashenblade = lib.nixosSystem {
            system = "aarch64-linux";
            modules = [ ./machines/kashenblade ] ++ commonModules;
          };

          kappril = lib.nixosSystem {
            system = "aarch64-linux";
            modules = [ ./machines/kappril ] ++ commonModules;
          };

          sempriaq = lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ ./machines/sempriaq ] ++ commonModules;
          };

          hetzner-template = lib.nixosSystem {
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

          blanderdash = lib.nixosSystem {
            system = "aarch64-linux";
            modules = [ ./machines/blanderdash ] ++ commonModules;
          };

          prandtl = lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              disko.nixosModules.disko
              lanzaboote.nixosModules.lanzaboote
              nixvirt.nixosModules.default
              ./machines/prandtl
            ] ++ commonModules;
          };
          glouble = lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              disko.nixosModules.disko
              # lanzaboote.nixosModules.lanzaboote
              ./machines/glouble
            ] ++ commonModules;
          };
          # MARKER_NIXOS_CONFIGURATIONS

          # ISO image for a up-to-date NixOS installer
          installer = lib.nixosSystem {
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
                    pkgs.nvme-cli
                    pkgs.util-linux
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
        gen-mail-account = pkgs.callPackage ./scripts/gen-mail-account.nix { };
        deploy-hosts = pkgs.callPackage ./scripts/deploy-hosts.nix { };
        fast-deploy = pkgs.callPackage ./scripts/fast-deploy.nix { };
        setup-host = pkgs.callPackage ./scripts/setup-host.nix { };
        add-antibuilding-peer = pkgs.callPackage ./scripts/add-antibuilding-peer.nix { };
        add-dn42-peer = pkgs.callPackage ./scripts/add-dn42-peer.nix { };
        add-workstation = pkgs.callPackage ./scripts/add-workstation.nix { };

        generate-docs = pkgs.callPackage ./scripts/generate-docs.nix { };
        generate-installer = pkgs.callPackage ./scripts/generate-installer.nix { };
        generate-raspi-image = pkgs.callPackage ./scripts/generate-raspi-image.nix { };
      };

      formatter.x86_64-linux = pkgs.nixpkgs-fmt;
    };
}
