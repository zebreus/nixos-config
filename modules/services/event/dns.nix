{ lib, config, ... }:
let
  inherit (config.meta.services.event) host baseDomain;
  server = config.meta.machines.${host};
in
{
  config.modules.dns.zones = lib.mkIf (host != null) {
    "${baseDomain}" = ''
      ; Records for $
      engel IN A ${server.staticIp4}
      engel IN AAAA ${server.staticIp6}
      pad IN A ${server.staticIp4}
      pad IN AAAA ${server.staticIp6}
      tickets IN A ${server.staticIp4}
      tickets IN AAAA ${server.staticIp6}
      wiki IN A ${server.staticIp4}
      wiki IN AAAA ${server.staticIp6}
      himmel IN CNAME engel.${baseDomain}
    '';
  };
}
