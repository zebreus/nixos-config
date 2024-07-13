{ lib, config, ... }:
let
  inherit (import ./helper.nix { inherit lib; }) quoteTxtEntry;
  machines = lib.attrValues config.machines;

  machinesThatAreAuthoritativeDnsServers = builtins.filter (machine: machine.authoritativeDns.enable) machines;

  primaryServer = lib.head (lib.filter (machine: machine.authoritativeDns.primary) machinesThatAreAuthoritativeDnsServers);
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
in
{
  config.modules.dns.zones = lib.mkIf thisServer.authoritativeDns.enable
    (builtins.listToAttrs (builtins.map
      (zone: {
        name = zone;
        value = (lib.mkMerge ([
          (lib.mkBefore ''
            $TTL 60
            $ORIGIN ${zone}.
            @ SOA ${primaryServer.authoritativeDns.name}.${config.modules.dns.mainDomain}. lennart.zebre.us. 1710300000 14400 3600 604800 300
          '')
          ''
            ; TXT for keyoxide
            @ IN TXT ${quoteTxtEntry "openpgp4fpr:2D53CFEA1AB4017BB327AFE310A46CC3152D49C5"}
          ''
        ]
        ++
        # Nameservers
        (lib.map
          (machine: "@ NS ${machine.authoritativeDns.name}.${config.modules.dns.mainDomain}.")
          machinesThatAreAuthoritativeDnsServers)
        ++
        # A and AAAA entries for the nameservers, if this is the main domain
        (if zone == config.modules.dns.mainDomain then
          (lib.concatMap
            (machine:
              (if machine.staticIp4 != null then [ "${machine.authoritativeDns.name} A ${machine.staticIp4}" ] else [ ])
                ++
                (if machine.staticIp6 != null then [ "${machine.authoritativeDns.name} AAAA ${machine.staticIp6}" ] else [ ])
            )
            machinesThatAreAuthoritativeDnsServers) else [ ]
        )));
      })
      managedZones));
}
