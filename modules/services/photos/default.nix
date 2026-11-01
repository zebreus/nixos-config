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
    # Their data is in /var/lib/isolated-containers/photos/lib on the host.
    modules.isolatedContainers.photos.config = {
      services.immich = {
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
          proxyPass = "http://${config.modules.isolatedContainers.photos.address}:${toString port}";
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
