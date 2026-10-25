{ lib, config, ... }:
let
  inherit (config.meta.services.suckmoreOrg) host baseDomain;
  server = config.meta.machines.${host};
in
{
  config.modules.dns.zones = lib.mkIf (host != null) {
    ${baseDomain} = ''
      ; Records for suckmore.org. The wildcard covers all the subdomains the
      ; suckmore-org nginx module serves (see modules/services/suckmore-org).
      @ IN A ${server.staticIp4}
      @ IN AAAA ${server.staticIp6}
      * IN A ${server.staticIp4}
      * IN AAAA ${server.staticIp6}
    '';
  };
}
