{ lib, config, ... }:
with lib;
let
  cfg = config.meta.self.photos;
  baseDomain = "zebre.us";
  port = 18282;
in
{
  imports = [ ./dns.nix ];

  config = mkIf cfg.enable {
    # immich, its database and its machine learning run in a gVisor sandbox.
    # What they persist is in /var/lib/isocon/photos on the host.
    isocon.photos = {
      ports = [ port ];
      # Media, database, job queue, and the machine learning's models.
      persist = [ "/var/lib/immich" "/var/lib/postgresql" "/var/lib/redis-immich" "/var/cache/immich" ];
      config.services.immich = {
        enable = true;
        inherit port;
        host = "0.0.0.0";
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts."photos.${baseDomain}" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString port}";
          proxyWebsockets = true;
          recommendedProxySettings = true;
          extraConfig = ''
            client_max_body_size 50000M;
            proxy_read_timeout   600s;
            proxy_send_timeout   600s;
            send_timeout         600s;
          '';
        };
      };
    };
  };
}
