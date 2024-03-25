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
    lib.nameValuePair "borgbackup-job-${name}"
      (if cfg.dontStartOnMeteredConnection then
        {
          serviceConfig = {
            ExecCondition = checkMeteredConnection;
          };
        } else { });
  mkBackupTimerMetered = name: cfg:
    lib.nameValuePair "borgbackup-job-${name}"
      (if cfg.dontStartOnMeteredConnection then
        {
          wants = [ "network-online.target" ];
        } else { });
in
with lib;
{
  options.services.borgbackup.jobs = with lib;
    mkOption
      {
        type = types.attrsOf
          (types.submodule (
            { name, config, ... }: {
              options = {
                dontStartOnMeteredConnection = mkOption {
                  type = types.bool;
                  default = false;
                  description = lib.mdDoc "Whether the backup will start if the connection is metered.";
                };
              };
            }
          ))
        ;
      };

  config = {
    systemd.services =
      mapAttrs' mkBackupServiceMetered config.services.borgbackup.jobs;

    systemd.timers =
      mapAttrs' mkBackupTimerMetered config.services.borgbackup.jobs;
  };
}
