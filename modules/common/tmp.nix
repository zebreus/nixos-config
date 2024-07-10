{ pkgs, lib, config, ... }: {
  options.modules.tmp.cleanTmpIfThereIsLessSpaceLeft = lib.mkOption {
    description = ''
      Clean the /tmp directory if there are less than this much KB left on the disk.
    '';
    type = lib.types.str;
    default = "3000000";
  };

  config = {
    systemd.tmpfiles = {
      settings = {
        "10-clean-tmp-regularly" = {
          "/tmp" = {
            "d" = {
              group = "root";
              mode = "1777";
              user = "root";
              age = "5d";
            };
            "d!" = {
              group = "root";
              mode = "1777";
              user = "root";
            };
          };
        };
      };
    };

    systemd.timers."clean-tmp-if-disk-is-full" = {
      enable = true;
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1h";
        OnUnitActiveSec = "1h";
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
          ${pkgs.coreutils}/bin/rm -rf /tmp/*
          # nix store gc
          # nix store optimise
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
