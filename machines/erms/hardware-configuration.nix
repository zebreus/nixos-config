{ config, lib, modulesPath, pkgs, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot = {
    initrd = {
      availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-intel" "i2c-dev" "ddcci_backlight" ];
    # TODO: Replace this with config.boot.kernelPackages.ddcci-driver once https://github.com/NixOS/nixpkgs/issues/297312 is fixed
    extraModulePackages = [
      (
        config.boot.kernelPackages.ddcci-driver.overrideAttrs (old: {
          patches = [
            (pkgs.fetchpatch {
              url = "https://gitlab.com/Sweenu/ddcci-driver-linux/-/commit/7f851f5fb8fbcd7b3a93aaedff90b27124e17a7e.patch";
              hash = "sha256-Y1ktYaJTd9DtT/mwDqtjt/YasW9cVm0wI43wsQhl7Bg=";
            })
          ];
        })
      )
    ];
  };


  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/ea1654a1-ffe8-4e09-8144-447742153719";
      fsType = "ext4";
    };
    "/mnt/toast" = {
      device = "/dev/disk/by-uuid/0eebe9bf-c476-4701-9d22-28eabfe79690";
      fsType = "ext4";
    };
    "/boot/efi" = {
      device = "/dev/disk/by-uuid/557D-EE3B";
      fsType = "vfat";
    };
    "/winefi" = {
      device = "/dev/disk/by-uuid/5EC8-3F73";
      fsType = "vfat";
    };
  };

  swapDevices = [ ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp11s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp9s0.useDHCP = lib.mkDefault true;

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
