{ modulesPath, lib, pkgs, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    # ./disk-config.nix
    ../../common/hetzner.nix
    ./hardware-configuration.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_6_7;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;

  boot.loader.grub = {
    enable = false;
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  services.openssh.enable = true;
  system.stateVersion = "23.11";

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
  ];

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDSzz3v/BNDgCZErzszVq064goCNv3KiQzt97DVXHFMg3VeYDv1okVXD2/jrf1Hxvjnh1LVeMN8vMbCp3jODYSI/nsXFqF2Br57QPN96fczUu/ew82iE3jlq5N0ZIMx9DUgIdvGBkj1Oj1W47K17bdE1+7EV03xwsWDVCVJid+ZtoSIF86IUZBaEmR29X/dsHrkTYMYjP0cCg4w8ihSQ1YBo//qI2KDS9ynj62vcOLEB67vKFX7U3Z7cmvYHWGJmSzQKwKsVTTOBGjhAumJPzSvo0ZdwinvZyKNq5ZPr3r9YEDKjzuwReKJSIse0+frbver3fEhD0y00pHD1QNij93231w7HfpSNT5MymdIpV4MKC/cdVbd598+p32CFur+iXQZfo7IkPH4hi7o66elv4yJF8Tk3w3bIOX7uCBL3+wiHkIQ/hq3dZ2slOA9J13uVfMSr/FVJRM8NnIB0kWdjzbYWYMJEDUEjmL6eJizIizL6JThstaYSXX0C/k1kpelKUs= lennart@erms"
  ];

  networking.hostName = "kashenblade-test";
  # networking.domain = "zebre.us";
  networking.useDHCP = false;
  networking.useNetworkd = true;

  modules.hetzner.wan = {
    enable = true;
    macAddress = "96:00:03:05:c8:32";
    ipAddresses = [
      "37.27.11.229/32"
      "2a01:4f9:c012:cc66::1/64"
    ];
  };
}
