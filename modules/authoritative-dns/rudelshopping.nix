{ lib, config, ... }:
let
  inherit (config.meta.services.rudelshopping) host baseDomain subDomain;
  server = config.meta.machines.${host};
  # Apex (@) when subDomain is null, otherwise the subdomain label.
  label = if subDomain == null then "@" else subDomain;
in
{
  config.modules.dns.zones = lib.mkIf (host != null) {
    ${baseDomain} = ''
      ; Records for rudelshopping
      ${label} IN A ${server.staticIp4}
      ${label} IN AAAA ${server.staticIp6}
      ; Redirect to the rudelblinken pad (vhost lives with the rudelshopping service)
      man IN A ${server.staticIp4}
      man IN AAAA ${server.staticIp6}
    '';
  };
}
