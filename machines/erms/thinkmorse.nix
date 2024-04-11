{ pkgs, lib, config, ... }:
{
  options = {
    services.thinkmorse = {
      enable = lib.mkEnableOption "Enable morse on the thinkpad led";
      message = lib.mkOption {
        type = lib.types.str;
        default = "Hello, World!";
        description = "The message to display in morse code";
      };
      devices = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "tpacpi::lid_logo_dot" ];
        description = "The devices to use for morse code";
      };
      speed = lib.mkOption {
        type = lib.types.str;
        default = "0.1";
        description = "Duration of a dit in seconds";
      };
    };
  };
  config = lib.mkIf config.services.thinkmorse.enable (
    let
      ditDelay = config.services.thinkmorse.speed;
      thinkmorse = pkgs.writeShellScriptBin "thinkmorse" ''
        #!${pkgs.bash}/bin/bash

        modprobe -r ec_sys
        modprobe ec_sys write_support=1

        led(){
          ${lib.concatStringsSep "\n" (builtins.map (device: ''echo $1 | ${pkgs.coreutils}/bin/tee /sys/class/leds/${device}/brightness'' ) config.services.thinkmorse.devices )}
        }

        dit(){
                led 1
                sleep ${ditDelay}
                led 0
                sleep ${ditDelay}
        }

        dah(){
                led 1
                sleep ${ditDelay}
                sleep ${ditDelay}
                sleep ${ditDelay}
                led 0
                sleep ${ditDelay}
        }

        morse(){
                case $1 in
                        "0") dah; dah; dah; dah; dah;;
                        "1") dit; dah; dah; dah; dah;;
                        "2") dit; dit; dah; dah; dah;;
                        "3") dit; dit; dit; dah; dah;;
                        "4") dit; dit; dit; dit; dah;;
                        "5") dit; dit; dit; dit; dit;;
                        "6") dah; dit; dit; dit; dit;;
                        "7") dah; dah; dit; dit; dit;;
                        "8") dah; dah; dah; dit; dit;;
                        "9") dah; dah; dah; dah; dit;;
                        "a") dit; dah;;
                        "b") dah; dit; dit; dit;;
                        "c") dah; dit; dah; dit;;
                        "d") dah; dit; dit;;
                        "e") dit;;
                        "f") dit; dit; dah; dit;;
                        "g") dah; dah; dit;;
                        "h") dit; dit; dit; dit;;
                        "i") dit; dit;;
                        "j") dit; dah; dah; dah;;
                        "k") dah; dit; dah;;
                        "l") dit; dah; dit; dit;;
                        "m") dah; dah;;
                        "n") dah; dit;;
                        "o") dah; dah; dah;;
                        "p") dit; dah; dah; dit;;
                        "q") dah; dah; dit; dah;;
                        "r") dit; dah; dit;;
                        "s") dit; dit; dit;;
                        "t") dah;;
                        "u") dit; dit; dah;;
                        "v") dit; dit; dit; dah;;
                        "w") dit; dah; dah;;
                        "x") dah; dit; dit; dah;;
                        "y") dah; dit; dah; dah;;
                        "z") dah; dah; dit; dit;;
                        " ") sleep ${ditDelay}; sleep ${ditDelay}; sleep ${ditDelay}; sleep ${ditDelay}; sleep ${ditDelay}; sleep ${ditDelay} ;;
                        #*) echo "done";;
                esac
                sleep 0.2;
        }

        parse(){
                tmp=$1
                for i in $(seq 0 ''${#tmp})
                do
                        echo "current letter: ''${tmp:$i:1}"
                        morse ''${tmp:$i:1}
                done
        }
        led 0
        parse "${config.services.thinkmorse.message}"
        led 0
        sleep 1
      '';
    in
    {
      systemd.services.thinkmorse = {
        enable = true;
        description = "Morse a message on the thinkpad led";
        after = [ "systemd-modules-load.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Restart = "always";
          Type = "simple";
          ExecStart = "${lib.getExe thinkmorse}";
        };
      };

    }
  );
}
