{ config
, lib
, pkgs
, ...
}:
{

  # Enable the community created Framework kernel module that allows interacting with the embedded controller from sysfs.
  boot.extraModulePackages = with config.boot.kernelPackages; [ framework-laptop-kmod ];
  # https://github.com/DHowett/framework-laptop-kmod?tab=readme-ov-file#usage
  boot.kernelModules = [
    "cros_ec"
    "cros_ec_lpcs"
    "amd_pstate=active"
  ];

  environment.systemPackages = [ pkgs.framework-tool ];

  # Custom udev rules
  services.udev.extraRules = ''
    # Ethernet expansion card support
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="8156", ATTR{power/autosuspend}="20"
  '';

  # Needed for desktop environments to detect/manage display brightness
  hardware.sensor.iio.enable = lib.mkDefault true;

  # Enable keyboard customization
  hardware.keyboard.qmk.enable = lib.mkDefault true;

  # AMD has better battery life with PPD over TLP:
  # https://community.frame.work/t/responded-amd-7040-sleep-states/38101/13
  services.power-profiles-daemon.enable = lib.mkDefault true;

  services.fstrim.enable = lib.mkDefault true;

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  services.xserver.videoDrivers = lib.mkDefault [ "modesetting" ];

  hardware.opengl = {
    driSupport = lib.mkDefault true;
    driSupport32Bit = lib.mkDefault true;
  };

  # For fingerprint support
  # services.fprintd.enable = lib.mkDefault true;

  #  boot.initrd.kernelModules = [ "amdgpu" ];
  #   hardware.opengl.extraPackages = (with pkgs; [
  #   amdvlk
  # ] ) ++ (with pkgs.rocmPackages; [ clr clr.icd ] );
  #  hardware.opengl.extraPackages32 = with pkgs; [
  #   driversi686Linux.amdvlk
  # ];
}
