{ lib, config, ... }:
let
  inherit (config.meta.services.besserestrichliste) host baseDomain subDomain;
  server = config.meta.machines.${host};
in
{
  config = lib.mkIf (host != null) {
    modules.dns.zones.${baseDomain} = ''
      ; Records for besserestrichliste
      ${subDomain} IN A ${server.staticIp4}
      ${subDomain} IN AAAA ${server.staticIp6}
    '';
  };
}
