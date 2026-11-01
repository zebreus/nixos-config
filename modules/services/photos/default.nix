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
    # Their data is in /var/lib/isocon/photos/lib on the host.
    modules.isocon.photos = {
      ports = [ port ];
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
