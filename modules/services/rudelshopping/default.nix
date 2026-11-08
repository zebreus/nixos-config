{ config, lib, ... }:
let
  cfg = config.meta.self.rudelshopping;
  domain = if cfg.subDomain == null then cfg.baseDomain else "${cfg.subDomain}.${cfg.baseDomain}";
  port = 3000;
in
{
  imports = [ ./dns.nix ];

  config = lib.mkIf cfg.enable {
    age.secrets.rudelshopping_stripe_key = {
      mode = "0400";
    };

    # The server runs in a gVisor sandbox. It keeps no state.
    isocon.rudelshopping = {
      tcpPorts = [ port ];
      credentials.stripe = config.age.secrets.rudelshopping_stripe_key.path;
      config.services.rudelshopping = {
        enable = true;
        host = "0.0.0.0";
        inherit port;
        origin = "https://${domain}";
        stripeKeyFile = "/run/credentials/@system/stripe";
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts.${domain} = {
        enableACME = true;
        forceSSL = true;
        locations."/".proxyPass = "http://127.0.0.1:${toString port}";
      };
      virtualHosts."man.${cfg.baseDomain}" = {
        enableACME = true;
        forceSSL = true;
        locations."/".extraConfig = ''
          return 307 https://md.darmstadt.ccc.de/rudelblinken-38c3;
        '';
      };
    };
  };
}
