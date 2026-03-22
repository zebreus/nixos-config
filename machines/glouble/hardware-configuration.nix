{ lib, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot = {
    initrd = {
      # uas is required for the usb hdds
      availableKernelModules = [ "uas" "ahci" "xhci_pci" "thunderbolt" "nvme" "usb_storage" "usbhid" "ohci_pci" "ehci_pci" "pata_amd" "sata_nv" "sd_mod" "rtsx_pci_sdmmc" ];
      kernelModules = [ "ahci" "xhci_pci" "thunderbolt" "nvme" "usb_storage" "usbhid" "ohci_pci" "ehci_pci" "pata_amd" "sata_nv" "sd_mod" "rtsx_pci_sdmmc" "bcachefs" ];
    };

    kernelModules = [ "uas" "ahci" "xhci_pci" "thunderbolt" "nvme" "usb_storage" "usbhid" "ohci_pci" "ehci_pci" "pata_amd" "sata_nv" "sd_mod" "rtsx_pci_sdmmc" "kvm-intel" "i2c-dev" ];
  };

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
