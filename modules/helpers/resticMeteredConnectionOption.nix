# Adds an option to restic backup jobs, so they do not start on metered connections
{ config, pkgs, lib, ... }:
let
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

  mkBackupServiceMetered = name: cfg:
    lib.nameValuePair "restic-backups-${name}"
      (if cfg.dontStartOnMeteredConnection then
        {
          serviceConfig = {
            ExecCondition = checkMeteredConnection;
          };
        } else { });
  mkBackupTimerMetered = name: cfg:
    lib.nameValuePair "restic-backups-${name}"
      (if cfg.dontStartOnMeteredConnection then
        {
          wants = [ "network-online.target" ];
        } else { });
in
with lib;
{
  options.services.restic.backups = with lib;
    mkOption
      {
        type = types.attrsOf
          (types.submodule (
            { name, config, ... }: {
              options = {
                dontStartOnMeteredConnection = mkOption {
                  type = types.bool;
                  default = false;
                  description = "Whether the backup will start if the connection is metered.";
                };
              };
            }
          ))
        ;
      };

  config = {
    systemd.services =
      mapAttrs' mkBackupServiceMetered config.services.restic.backups;

    systemd.timers =
      mapAttrs' mkBackupTimerMetered config.services.restic.backups;
  };
}
