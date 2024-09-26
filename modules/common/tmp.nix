{ pkgs, lib, config, ... }:
let
  thisMachine = config.machines."${config.networking.hostName}";
in
{

  config = {
    systemd.tmpfiles = lib.mkIf thisMachine.auto-maintenance.cleanup {
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
      enable = thisMachine.auto-maintenance.cleanup;
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "15m";
        OnUnitActiveSec = "15m";
        Unit = "clean-tmp-if-disk-is-full.service";
      };
    };
    systemd.services."clean-tmp-if-disk-is-full" = {
      enable = thisMachine.auto-maintenance.cleanup;
      script = ''
        SIZE_LEFT="$(${pkgs.coreutils}/bin/df / --output="avail"  -B1024 | ${pkgs.coreutils}/bin/tail -n 1)"
        if test -z "$SIZE_LEFT" ; then
          echo "Could not get the disk size"
          exit 1
        fi
        if test "$SIZE_LEFT" -lt "${thisMachine.auto-maintenance.cleanTmpIfThereIsLessSpaceLeft}" ; then
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
