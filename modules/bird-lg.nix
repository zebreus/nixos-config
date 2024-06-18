{ config, lib, ... }:
let
  machines = lib.attrValues config.machines;
  thisMachine = config.machines."${config.networking.hostName}";
in
{
  config = lib.mkIf thisMachine.bird-lg.enable {
    networking.firewall = {
      allowedTCPPorts = [ 443 ];
    };
    security.acme = {
      acceptTerms = true;
      defaults.email = "lennarteichhorn@googlemail.com";
    };
    services = {
      bird-lg = {
        frontend = {
          domain = "lg.antibuild.ing";
          enable = true;
          servers = (builtins.map (machine: machine.name) machines);
          protocolFilter = [ "bgp" "static" ];
          listenAddress = "127.0.0.1:15000";
          proxyPort = 18000;
          navbar = {
            brand = "Antibuilding";
          };
        };
      };
      nginx.virtualHosts = {
        "lg.antibuild.ing" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://${config.services.bird-lg.frontend.listenAddress}";
            proxyWebsockets = true;
          };
        };
      };

    };
  };
}
