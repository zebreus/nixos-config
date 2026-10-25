{ lib, config, ... }:
let
  host = config.meta.services.photos.host;
  server = config.meta.machines.${host};
  baseDomain = "zebre.us";
in
{
  config.modules.dns.zones = lib.mkIf (host != null) {
    "${baseDomain}" = ''
      ; Records for $
      photos IN A ${server.staticIp4}
      photos IN AAAA ${server.staticIp6}
    '';
  };
}
