{ config, lib, ... }:
let
  cfg = config.meta.self.besserestrichliste;
  port = 12854;
in
{
  imports = [ ./dns.nix ];

  config = lib.mkIf cfg.enable {
    # Temporary besserestrichliste deployment
    isocon.besserestrichliste = {
      tcpPorts = [{ inherit port; ipv6 = true; }];
      # The SQLite database, and npm's cache from the migrations at every start.
      # Backed up as a whole, so that a backup also gets SQLite's journal.
      persist = [{ path = "/var/lib/besserestrichliste"; backup = true; }];
      duringBackup = "pause";
      config.services.besserestrichliste = {
        enable = true;
        inherit port;
        host = "::";
        origin = "https://besserer.wirs.ing";
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts = {
        "besserer.wirs.ing" = {
          enableACME = true;
          forceSSL = true;
          locations = {
            "/".proxyPass = "http://[::1]:${toString port}";
          };
        };
      };
    };
  };
}
