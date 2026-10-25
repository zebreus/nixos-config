# Lets restic backup jobs skip starting while the connection is metered, as
# reported by NetworkManager. On by default wherever NetworkManager runs.
{ lib, config, pkgs, ... }:
let
  networkmanager = config.networking.networkmanager.enable;

  checkMeteredConnection = pkgs.writeScript "check-metered-connection.sh" ''
    #!${lib.getExe pkgs.bash}

    metered_status=$(${pkgs.dbus}/bin/dbus-send --system --print-reply=literal \
            --system --dest=org.freedesktop.NetworkManager \
              /org/freedesktop/NetworkManager \
              org.freedesktop.DBus.Properties.Get \
              string:org.freedesktop.NetworkManager string:Metered \
              | grep -o ".$")

    if [[ $metered_status =~ (1|3) ]]; then
      echo Current connection is metered
      exit 1
    else
      exit 0
    fi
  '';

  meteredBackups = lib.filterAttrs (_: backup: backup.dontStartOnMeteredConnection) config.services.restic.backups;
  forEachMeteredBackup = unit: lib.mapAttrs' (name: _: lib.nameValuePair "restic-backups-${name}" unit) meteredBackups;
in
{
  options.services.restic.backups = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options.dontStartOnMeteredConnection = lib.mkOption {
        type = lib.types.bool;
        default = networkmanager;
        defaultText = lib.literalExpression "config.networking.networkmanager.enable";
        description = "Whether the backup skips starting while the connection is metered. Needs NetworkManager.";
      };
    });
  };

  config = {
    assertions = [{
      assertion = meteredBackups == { } || networkmanager;
      message = "services.restic.backups.<name>.dontStartOnMeteredConnection is set for ${lib.concatStringsSep ", " (builtins.attrNames meteredBackups)}, but NetworkManager (networking.networkmanager.enable), which reports whether the connection is metered, is not enabled.";
    }];

    systemd.services = forEachMeteredBackup { serviceConfig.ExecCondition = checkMeteredConnection; };
    systemd.timers = forEachMeteredBackup { wants = [ "network-online.target" ]; };
  };
}
