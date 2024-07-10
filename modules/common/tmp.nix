{ pkgs, lib, config, ... }: {
  options.modules.tmp.cleanTmpIfThereIsLessSpaceLeft = lib.mkOption {
    description = ''
      Clean the /tmp directory if there are less than this much KB left on the disk.
    '';
    type = lib.types.str;
    default = "2000000";
  };

  config = {
    systemd.tmpfiles = {
      settings = {
        "00-clean-on-reboot" = {
          "/tmp" = {
            # Delete everything in /tmp on boot
            "D!" = {
              user = "root";
              group = "root";
              mode = "1777";
              age = "0";
            };
          };
          "/var/tmp" = {
            # Delete everything in /tmp on boot
            "D!" = {
              user = "root";
              group = "root";
              mode = "1777";
              age = "0";
            };
          };
        };
      };
    };

    # Delete everything in /tmp if the disk gets too full
    systemd.timers."clean-tmp-if-disk-is-full" = {
      enable = true;
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "15m";
        OnUnitActiveSec = "15m";
        Unit = "clean-tmp-if-disk-is-full.service";
      };
    };
    systemd.services."clean-tmp-if-disk-is-full" = {
      enable = true;
      script = ''
        SIZE_LEFT="$(${pkgs.coreutils}/bin/df / --output="avail"  -B1024 | ${pkgs.coreutils}/bin/tail -n 1)"
        if test -z "$SIZE_LEFT" ; then
          echo "Could not get the disk size"
          exit 1
        fi
        if test "$SIZE_LEFT" -lt "${config.modules.tmp.cleanTmpIfThereIsLessSpaceLeft}" ; then
          echo "Cleaning tmp because the disk is full"
          set -x
          shopt -s dotglob
          ${pkgs.coreutils}/bin/rm -rf /tmp/*
          ${pkgs.coreutils}/bin/rm -rf /var/tmp/*
          ${pkgs.systemd}/bin/systemd-tmpfiles --clean
          # nix store gc
          # nix store optimise
          set +x
        else
          echo "Disk is not full"
        fi
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
    };
  };
}
