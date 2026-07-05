{ config, lib, ... }:
let
  cfg = config.meta.self.rudelshopping;
  domain = if cfg.subDomain == null then cfg.baseDomain else "${cfg.subDomain}.${cfg.baseDomain}";
  port = 3000;
in
{
  config = lib.mkIf cfg.enable {
    age.secrets.rudelshopping_stripe_key = {
      file = ../secrets/rudelshopping_stripe_key.age;
      # LoadCredential reads this as root (PID 1) before the service drops
      # privileges, so root-only is fine and most secure.
      mode = "0400";
    };

    services.rudelshopping = {
      enable = true;
      host = "[::1]";
      inherit port;
      origin = "https://${domain}";
      stripeKeyFile = config.age.secrets.rudelshopping_stripe_key.path;
    };

    services.nginx = {
      enable = true;
      virtualHosts.${domain} = {
        enableACME = true;
        forceSSL = true;
        locations."/".proxyPass = "http://[::1]:${toString port}";
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
