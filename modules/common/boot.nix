{
  pkgs,
  config,
  lib,
  ...
}:
{
  options.modules.boot.type = lib.mkOption {
    description = ''
      How to configure the boot loader. The default is "efi" which installs systemd-boot into `/boot/efi`.

      "legacy" uses grub for BIOS systems. "raspi" uses extlinux for Raspberry Pi.
    '';
    type = lib.types.enum [
      "efi"
      "legacy"
      "raspi"
      "secure"
    ];
    default = "efi";
  };

  config = {

    boot = {
      kernelPackages = pkgs.linuxPackages_latest;

      lanzaboote = lib.mkIf (config.modules.boot.type == "secure") {
        enable = true;
        pkiBundle = "/etc/secureboot";
      };


      loader =
        {
          legacy = { };
          efi = {
            grub.enable = false;
            systemd-boot.enable = true;
            efi.canTouchEfiVariables = true;
            efi.efiSysMountPoint = "/boot/efi";
          };
          raspi = {
            grub.enable = false;
            generic-extlinux-compatible.enable = true;
          };
          secure = {
            grub.enable = false;

            # Lanzaboote currently replaces the systemd-boot module.
            # This setting is usually set to true in configuration.nix
            # generated at installation time. So we force it to false
            # for now.
            systemd-boot.enable = lib.mkForce false;
          };
        }
        .${config.modules.boot.type};
    };

      # Enable auto-login if secureboot is enabled
      services.displayManager.autoLogin = lib.mkIf (config.modules.boot.type == "secure") {
        enable = true;
        user = "lennart";
      };
      
    environment.systemPackages = lib.mkIf (config.modules.boot.type == "secure") [ pkgs.sbctl ];
  };
}
