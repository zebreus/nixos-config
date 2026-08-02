{ lib, config, ... }:
let
  cfg = config.meta.self.chaosdarmstadt;
  baseDomain = "chaosdarmstadt.de";
in
{
  config = lib.mkIf cfg.enable {
    services.nginx = {
      enable = true;
      virtualHosts = lib.genAttrs [ baseDomain "www.${baseDomain}" ] (domain: {
        enableACME = true;
        forceSSL = true;
        locations."/".extraConfig = ''
          return 307 https://chaos-darmstadt.de$request_uri;
        '';
      });
    };
  };
}
