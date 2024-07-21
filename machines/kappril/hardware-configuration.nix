# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ lib, modulesPath, pkgs, config, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
      (modulesPath + "/installer/sd-card/sd-image.nix")
    ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "uas"
    # Allows early (earlier) modesetting for the Raspberry Pi
    "vc4"
    "bcm2835_dma"
    "i2c_bcm2835"
    # Allows early (earlier) modesetting for Allwinner SoCs
    "sun4i_drm"
    "sun8i_drm_hdmi"
    "sun8i_mixer"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];
  # The serial ports listed here are:
  # - ttyS0: for Tegra (Jetson TX1)
  # - ttyAMA0: for QEMU's -machine virt
  boot.kernelParams =
    [ "console=ttyS0,115200n8" "console=ttyAMA0,115200n8" "console=tty0" ];

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_8;
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  boot.supportedFilesystems.bcachefs = lib.mkForce true;
  boot.supportedFilesystems.zfs = lib.mkForce false;

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = [ "defaults" "noatime" ];
  };

  # fileSystems."/storage" = {
  #   device = "/dev/disk/by-uuid/9cb27da6-d189-4f8d-8070-6ea445d0cd50";
  #   fsType = "bcachefs";
  #   options = [ "defaults" "nofail" "x-systemd.device-timeout=600" "x-systemd.mount-timeout=600" "verbose" ];
  # };

  # swapDevices = [{
  #   device = "/swapfile";
  #   # 12 GB
  #   size = 1000 * 12;
  # }];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.end0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlan0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  sdImage = {
    populateFirmwareCommands =
      let
        configTxt = pkgs.writeText "config.txt" ''
          [pi3]
          kernel=u-boot-rpi3.bin
          [pi4]
          kernel=u-boot-rpi4.bin
          enable_gic=1
          armstub=armstub8-gic.bin
          # Otherwise the resolution will be weird in most cases, compared to
          # what the pi3 firmware does by default.
          disable_overscan=1
          [all]
          # Boot in 64-bit mode.
          arm_64bit=1
          # U-Boot needs this to work, regardless of whether UART is actually used or not.
          # Look in arch/arm/mach-bcm283x/Kconfig in the U-Boot tree to see if this is still
          # a requirement in the future.
          enable_uart=1
          # Prevent the firmware from smashing the framebuffer setup done by the mainline kernel
          # when attempting to show low-voltage or overtemperature warnings.
          avoid_warnings=1
        '';
      in
      ''
        (cd ${pkgs.raspberrypifw}/share/raspberrypi/boot && cp bootcode.bin fixup*.dat start*.elf $NIX_BUILD_TOP/firmware/)
        # Add the config
        cp ${configTxt} firmware/config.txt
        # Add pi3 specific files
        cp ${pkgs.ubootRaspberryPi3_64bit}/u-boot.bin firmware/u-boot-rpi3.bin
        # Add pi4 specific files
        cp ${pkgs.ubootRaspberryPi4_64bit}/u-boot.bin firmware/u-boot-rpi4.bin
        cp ${pkgs.raspberrypi-armstubs}/armstub8-gic.bin firmware/armstub8-gic.bin
        cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2711-rpi-4-b.dtb firmware/
      '';
    populateRootCommands = ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
  };
}
