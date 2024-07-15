{ lib, config, ... }:
let
  inherit (import ./helper.nix { inherit lib; }) quoteTxtEntry;
  machines = lib.attrValues config.machines;
  machinesThatAreAuthoritativeDnsServers = builtins.filter (machine: machine.authoritativeDns.enable) machines;
  thisServer = config.machines.${config.networking.hostName};

  managedZones = [
    "antibuild.ing"
    # Used for my external stuff. Matrix, mail, etc.
    "zebre.us"
    # My old email server lived here. Now it's just a redirect to the new one
    "madmanfred.com"
    # I use this domains for hosting random stuff with github pages
    "wirs.ing"
    # My old matrix server
    "cicen.net"
    # I use this domain for testing
    "del.blue"
    # Hosts a badly drawn picture of a unicorn
    "einhorn.jetzt"
    # Hosts a now defunct and unfinished project for ai generated shirts
    "generated.fashion"
    # Hosts a broken test of a gunjs based blog
    "xn--f87c.cc"
    # Maybe I will use this for an url shortener or something. nothing for now
    "zeb.rs"
  ];
  managedZonesDn42 = [
    # dn42 domain for internal services
    "antibuilding.dn42"
    # dn42 for other stuff
    "zebreus.dn42"
    # ipv6 reverse DNS
    "0.0.0.0.0.3.0.2.0.1.d.f.ip6.arpa"
    # ipv4 reverse DNS
    "128/27.179.20.172.in-addr.arpa"
  ];

  zoneContent = zone: nameservers: lib.mkMerge ([
    (lib.mkBefore ''
      $TTL 60
      $ORIGIN ${zone}.
      @ SOA ${(lib.findSingle (nameserver: nameserver.primary) null null nameservers).name}. lennart.zebre.us. 0 14400 3600 604800 300
    '')
    ''
      ; TXT for keyoxide
      @ IN TXT ${quoteTxtEntry "openpgp4fpr:2D53CFEA1AB4017BB327AFE310A46CC3152D49C5"}
    ''
  ]
  ++
  # Nameservers
  (lib.map
    (nameserver: "@ NS ${nameserver.name}.")
    nameservers)
  ++
  # A and AAAA entries for the nameservers, if this is the main domain
  (lib.concatMap
    (nameserver:
      (if nameserver.ip4 != null then [ "${lib.removeSuffix ".${zone}" nameserver.name} A ${nameserver.ip4}" ] else [ ])
        ++
        (if nameserver.ip6 != null then [ "${lib.removeSuffix ".${zone}" nameserver.name} AAAA ${nameserver.ip6}" ] else [ ])
    )
    (lib.filter (nameserver: lib.hasSuffix ".${zone}" nameserver.name) nameservers)
  ));
in
{
  config.modules.dns.zones = lib.mkIf thisServer.authoritativeDns.enable
    (
      (builtins.listToAttrs (builtins.map
        (zone: {
          name = zone;
          value = zoneContent zone (lib.map
            (machine: {
              name = machine.authoritativeDns.name + "." + config.modules.dns.mainDomain;
              ip4 = machine.staticIp4;
              ip6 = machine.staticIp6;
              primary = machine.authoritativeDns.primary;
            })
            machinesThatAreAuthoritativeDnsServers);
        })
        managedZones))
      //
      (builtins.listToAttrs (builtins.map
        (zone: {
          name = zone;
          value = zoneContent zone (lib.map
            (machine: {
              name = machine.authoritativeDns.name + ".antibuilding.dn42";
              ip4 = "172.20.179.${builtins.toString (machine.address + 128)}";
              ip6 = "${config.antibuilding.ipv6Prefix}::${builtins.toString machine.address}";
              primary = machine.authoritativeDns.primary;
            })
            machinesThatAreAuthoritativeDnsServers);
        })
        managedZonesDn42))
    );
}
