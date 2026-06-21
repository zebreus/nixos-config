{ config
, lib
, ...
}:
let
  cfg = config.meta.self.suckmoreOrg;

  subdomains = [
    "wiki"
    "hg"
    "oldhg"
    "dmenu"
    "wmii"
    "mx"
    "gunther"
    "oldgit"
    "lists"
    "core"
    "dl"
    "surf"
    "stagit"
    "www"
    "dwm"
    "ev"
    "git"
    "libs"
    "st"
    "tools"
  ];
in
{
  config = lib.mkIf cfg.enable {
    services.suckmore-org = {
      enable = true;
      port = 49321;
      host = "[::]";
    };

    services.nginx = {
      enable = true;
      commonHttpConfig = lib.mkIf cfg.enableCaching ''
        limit_req_zone $binary_remote_addr zone=mylimit2:10m rate=600r/m;
      '';
      virtualHosts = lib.mkMerge (
        builtins.map
          (domain: {
            "${domain}" = {
              enableACME = true;
              forceSSL = true;
              locations = {
                "/" = {
                  proxyPass = "http://[::1]:" + builtins.toString config.services.suckmore-org.port;
                  extraConfig = lib.mkIf cfg.enableCaching ''
                    proxy_cache_key $scheme://$host$uri$is_args$query_string;
                    proxy_cache_valid 200 10m;
                    limit_req zone=mylimit2 burst=10;
                  '';
                };
              };
            };
          })
          ([ cfg.baseDomain ] ++ (builtins.map (subdomain: "${subdomain}.${cfg.baseDomain}") subdomains))
      );
    };
  };
}
