{ lib, config, ... }:
let
  host = config.meta.services.chaosdarmstadt.host;
  server = config.meta.machines.${host};
in
{
  config.modules.dns.zones = lib.mkIf (host != null) {
    "chaosdarmstadt.de" = ''
      ; Redirects to chaos-darmstadt.de (see modules/chaosdarmstadt.nix)
      @ IN A ${server.staticIp4}
      @ IN AAAA ${server.staticIp6}
      www IN A ${server.staticIp4}
      www IN AAAA ${server.staticIp6}
    '';
  };
}
