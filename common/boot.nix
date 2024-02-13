{ config, pkgs, ... }:
{

  boot.kernelPackages = pkgs.linuxPackages_6_1;
  boot.extraModprobeConfig = ''
    options thinkpad_acpi fan_control=1
    # exclusive_caps: Skype, Zoom, Teams etc. will only show device when actually streaming
    # card_label: Name of virtual camera, how it'll show up in Skype, Zoom, Teams
    # https://github.com/umlaeute/v4l2loopback
    options v4l2loopback exclusive_caps=1 card_label="Virtual Camera"
  '';
  boot.extraModulePackages = with config.boot.kernelPackages;
    [ v4l2loopback.out ];
  # Activate kernel modules (choose from built-ins and extra ones)
  boot.kernelModules = [
    # Virtual Camera
    "v4l2loopback"
    # Virtual Microphone, built-in
    "snd-aloop"
  ];
  boot.kernelParams = [
    # "acpi_backlight=nvidia_wmi_ec"
    # "acpi_backlight=vendor"
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
}
