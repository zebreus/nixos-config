{ config
, lib
, pkgs
, ...
}:
{

  # Enable the community created Framework kernel module that allows interacting with the embedded controller from sysfs.
  # boot.extraModulePackages = with config.boot.kernelPackages; [ framework-laptop-kmod ];
  # https://github.com/DHowett/framework-laptop-kmod?tab=readme-ov-file#usage
  boot.kernelModules = [
    "cros_ec"
    "cros_ec_lpcs"
    "amd_pstate=active"
  ];

  environment.systemPackages = [ pkgs.framework-tool ];

  # Custom udev rule for the ethernet cart
  services.udev.extraRules = ''
    # # Ethernet expansion card support
    # ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="8156", ATTR{power/autosuspend}="20"

    # Allow access to the keyboard modules for programming, for example by
    # visiting https://keyboard.frame.work with a WebHID-compatible browser.
    #
    # https://community.frame.work/t/responded-help-configuring-fw16-keyboard-with-via/47176/5
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="32ac", ATTRS{idProduct}=="0012", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
  '';

  # Needed for desktop environments to detect/manage display brightness
  hardware.sensor.iio.enable = lib.mkDefault true;

  # Enable keyboard customization
  hardware.keyboard.qmk.enable = lib.mkDefault true;

  # AMD has better battery life with PPD over TLP:
  # https://community.frame.work/t/responded-amd-7040-sleep-states/38101/13
  services.power-profiles-daemon.enable = lib.mkDefault true;

  services.fstrim.enable = lib.mkDefault true;

  # Not sure if this improves boot time
  # hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  services.xserver.videoDrivers = lib.mkDefault [ "modesetting" ];

  # For fingerprint support
  # services.fprintd.enable = lib.mkDefault true;

  #  boot.initrd.kernelModules = [ "amdgpu" ];
  #   hardware.opengl.extraPackages = (with pkgs; [
  #   amdvlk
  # ] ) ++ (with pkgs.rocmPackages; [ clr clr.icd ] );
  #  hardware.opengl.extraPackages32 = with pkgs; [
  #   driversi686Linux.amdvlk
  # ];

  # Allow `services.libinput.touchpad.disableWhileTyping` to work correctly.
  # Set unconditionally because libinput can also be configured dynamically via
  # gsettings.
  #
  # This is extracted from the quirks file that is in the upstream libinput
  # source.  Once we can assume everyone is on at least libinput 1.26.0, this
  # local override file can be removed.
  # https://gitlab.freedesktop.org/libinput/libinput/-/commit/566857bd98131009699c9ab6efc7af37afd43fd0
  environment.etc."libinput/local-overrides.quirks".text = ''
    [Framework Laptop 16 Keyboard Module]
    MatchName=Framework Laptop 16 Keyboard Module*
    MatchUdevType=keyboard
    MatchDMIModalias=dmi:*svnFramework:pnLaptop16*
    AttrKeyboardIntegration=internal
  '';
}
