{ pkgs, lib, config, ... }: with lib; let
  cfg = config.services.secret-service-passwords;
in
{

  options = {
    services.secret-service-passwords = {
      enable = mkEnableOption "Enable managing passwords with the secret service.";

      secrets = mkOption {
        default = { };
        type = types.listOf (types.submodule ({ lib, name, ... }: with lib;{
          options = {
            label = mkOption {
              type = types.str;
              default = name;
              description = "The label of this password. Will be displayed to the user.";
            };
            passwordCommand = mkOption {
              type = types.str;
              description = "The command to run to get the password. The command will get run once on every session start and the result will be stored in the secret service.";
            };
            attributes = mkOption {
              type = types.attrsOf types.str;
              default = { };
              description = "Attributes to add to the password in the secret service.";
            };
          };
        }));
      };
    };


  };

  config = lib.mkIf cfg.enable {
    systemd.user = {
      startServices = "sd-switch";
      services.secret-service-passwords =
        let
          storePasswordCommands = lib.concatStringsSep "\n" (
            builtins.map
              (
                { label, passwordCommand, attributes }:
                let
                  attributesToString = attrs: lib.concatStringsSep " " (lib.mapAttrsToList (name: value: "'${name}' '${value}'") attrs);
                in
                "${passwordCommand} | ${lib.getExe pkgs.gnused} -z '$ s/\\n$//' | storeManagedSecret --label='${label}' ${attributesToString attributes}"
              )
              cfg.secrets
          );

          startScript = pkgs.writeScript "updatePasswords.sh" ''
            #!${lib.getExe pkgs.bash}
            set -e

            # This script will use libsecret to remove any old home-manager passwords from the secret service

            if ! ${lib.getExe pkgs.lssecret} > /dev/null
            then
              echo "Secret service not available, skipping password insertion"
              exit 1
            fi

            # Removes all managed secrets
            function removeManagedSecrets {
                # Will return 1 when there are no secrets to remove
                # We do not want to fail in that case which also results in a failure
                ${lib.getExe pkgs.libsecret} clear home-manager-secret dont-modify-this-manually || true
            }

            # Store a secret and mark it as managed by home-manager
            # Reads the secret from stdin
            function storeManagedSecret {
                local secret
                local secret_hash
                secret="$(cat)"
                secret_hash="$(echo "$@" "$secret" | sha256sum | cut -f1 -d' ')"
                echo -n "$secret" | ${lib.getExe pkgs.libsecret} store home-manager-secret dont-modify-this-manually home-manager-secret-hash "$secret_hash" "$@"
            }

            function storeImapSmtpPassword {
                local name=$1
                local password=$2

                echo "Storing SMTP/IMAP password for $name"
                echo -n "{'imap-password': <'$password'>, 'smtp-password': <'$password'>}" | storeManagedSecret --label="GOA imap_smtp credentials for identity $name" xdg:schema org.gnome.OnlineAccounts goa-identity imap_smtp:gen0:"$name"
            }

            # Clear previous secrets
            echo "Removing old secrets"
            removeManagedSecrets
            # Store new secrets
            echo "Storing new secrets"
            ${storePasswordCommands}

            exit 0
          '';

          stopScript = pkgs.writeScript "removePasswords.sh" ''
            #!${lib.getExe pkgs.bash}

            # This script will remove all home-manager passwords from the secret service.
            # It is not strictly necessary, but it is a good idea to clean up after ourselves.

            set -e

            if ! ${lib.getExe pkgs.lssecret} > /dev/null
            then
              echo "Error: Secret service not available. Cannot remove secrets."
              exit 1
            fi

            # Will return 1 when there are no secrets to remove
            # We do not want to fail in that case which also results in a failure
            ${lib.getExe pkgs.libsecret} clear home-manager-secret dont-modify-this-manually || true
          '';
        in
        {
          Unit = {
            Description = "Insert passwords into the secret service";
            After = [ "default.target" "dbus.service" ];
            PartOf = [ "default.target" ];
          };

          Service = {
            Type = "oneshot";
            RemainAfterExit = true;
            StandardOutput = "journal";
            ExecStart = "${startScript}";
            ExecStop = "${stopScript}";
            Restart = "on-failure";
            RestartSec = 2;
            StartLimitInterval = 60;
            StartLimitBurst = 5;
            X-SwitchMethod = "restart";
          };

          Install = { WantedBy = [ "default.target" "graphical-session.target" ]; };
        };
    };
  };
}
