{ lib, modulesPath, config, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot = {
    initrd = {
      availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "usbhid" "sd_mod" "rtsx_pci_sdmmc" ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-intel" "i2c-dev" ];
    # extraModulePackages = [
    #   # config.boot.kernelPackages.rtl8192eu
    #   config.boot.kernelPackages.rtl8189fs
    #   config.boot.kernelPackages.rtl8189es
    #   config.boot.kernelPackages.rtl8852bu
    #   # config.boot.kernelPackages.rtl8852au
    #   # config.boot.kernelPackages.rtl8188eus-aircrack
    # ];
  };
  nixpkgs.config.allowBroken = true;


  fileSystems = {
    # ...
  };

  swapDevices = [ ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault false;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
