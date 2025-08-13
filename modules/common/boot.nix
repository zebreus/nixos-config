{ pkgs
, config
, lib
, ...
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
      "secure-firstboot"
    ];
    default = "efi";
  };

  config = {

    boot = lib.mkMerge [
      {
        kernelPackages = pkgs.linuxPackages_testing;
        initrd.systemd.extraConfig = ''
                
        '';

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
            # IMPORTANT: When configuring a new machine with secureboot use secure-firstboot for the install
            secure = {
              grub.enable = false;

              # Lanzaboote currently replaces the systemd-boot module.
              # This setting is usually set to true in configuration.nix
              # generated at installation time. So we force it to false
              # for now.
              systemd-boot.enable = lib.mkForce false;
              # Editor is not secure
              systemd-boot.editor = true;
            };
            secure-firstboot = {
              grub.enable = false;

              # We need to use the normal systemd-boot when installing a secureboot machine
              systemd-boot.enable = true;
              # Editor is not secure
              systemd-boot.editor = true;
            };


          }.${config.modules.boot.type};
      }
      (
        if (config.modules.boot.type == "secure") then
          {
            lanzaboote = {
              enable = true;
              pkiBundle = "/etc/secureboot";
            };

            # Enable systemd in stage 1
            # initrd.systemd.enable = true;
          }
        else
          { }
      )
    ];

    environment.systemPackages = lib.mkIf (config.modules.boot.type == "secure" || config.modules.boot.type == "secure-firstboot") [ pkgs.sbctl ];
  };
}
