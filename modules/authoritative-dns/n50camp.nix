{ lib, config, ... }:
let
  staticRecord = subdomain: { staticIp4, staticIp6, ... }: (
    (if staticIp4 == null then "" else ''
      ${subdomain} IN A ${staticIp4}
    '')
    +
    (if staticIp6 == null then "" else ''
      ${subdomain} IN AAAA ${staticIp6}
    '')
  );

  machines = lib.attrValues config.machines;
  n50Servers = lib.filter (machine: machine.n50campServer.enable) machines;
  n50Server = lib.head n50Servers;
  baseDomains = n50Server.n50campServer.baseDomains;

  # The same set of records is published verbatim under every base domain, so
  # all names resolve to the event server. The host nginx then serves the apps on
  # the primary base domain and redirects the secondaries to it.
  recordsForZone = ''
    ; Records for the N50 camp event server
  '' +
  (staticRecord "@" n50Server) +
  (staticRecord "engel" n50Server) +
  (staticRecord "tickets" n50Server) +
  (staticRecord "pad" n50Server) +
  (staticRecord "wiki" n50Server);
in
{
  config = lib.mkIf (n50Servers != [ ]) {
    modules.dns.zones = lib.mkMerge (builtins.map
      (baseDomain: { ${baseDomain} = recordsForZone; })
      baseDomains);
  };
}
