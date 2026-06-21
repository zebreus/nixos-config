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

  inherit (config.meta.services.gulaschSites) host baseDomain;
  gulaschServer = config.meta.machines.${host};

  # One record per static gulasch.site property served by the gulasch-sites
  # nginx module (see modules/gulasch-sites.nix). Each subdomain resolves to the
  # host that serves it. The apex ("@") is served too: the module hosts the
  # analytics site at the bare base domain.
  subdomains = [
    "@"
    "ocpncord"
    "pokemon"
    "drive"
    "aisaas"
    "c3cock"
    "testwebseite"
    "testwebseite2"
    "chat"
    "angular"
    "n50camp"
    "bagger"
    "analytics"
  ];

  records = ''
    ; Records for the static gulasch.site web properties
  '' + lib.concatStrings (builtins.map (sub: staticRecord sub gulaschServer) subdomains);
in
{
  config = lib.mkIf (host != null) {
    modules.dns.zones.${baseDomain} = records;
  };
}
