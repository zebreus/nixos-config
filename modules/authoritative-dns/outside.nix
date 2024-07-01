{ lib, config, ... }:
let
  machines = lib.attrValues config.machines;
  serversWithStaticIpv4 = lib.filter (machine: machine.staticIp4 != null) machines;
  serversWithStaticIpv6 = lib.filter (machine: machine.staticIp6 != null) machines;
in
{
  config.modules.dns.zones.${config.modules.dns.mainDomain} = lib.mkMerge ([
    ''
      ; Records for globally reachable static ips
    ''
  ] ++
  (builtins.map
    (machine: ''
      ; Public ipv4 entry for ${machine.name}
      ${machine.name}.outside IN A ${builtins.toString machine.staticIp4}
    '')
    serversWithStaticIpv4)
  ++
  (builtins.map
    (machine: ''
      ; Public ipv6 entry for ${machine.name}
      ${machine.name}.outside IN AAAA ${builtins.toString machine.staticIp6}
    '')
    serversWithStaticIpv6)
  );
}
