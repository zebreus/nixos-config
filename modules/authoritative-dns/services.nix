{ lib, config, ... }:
let
  machines = lib.attrValues config.machines;

  # splitStringIntoChunks = str -> int -> [str]
  splitStringIntoChunks = str: maxLength:
    let
      numberOfChunks = 1 + (((builtins.stringLength str) - 1) / maxLength);
    in
    builtins.map (i: builtins.substring (i * maxLength) maxLength str) (lib.range 0 (numberOfChunks - 1));

  # Quote a string and split it into chunks for a TXT record
  # quoteTxtEntry = str -> str
  quoteTxtEntry = str:
    let
      chunks = splitStringIntoChunks str 250;
    in
    builtins.concatStringsSep " " (builtins.map (s: "\"" + s + "\"") chunks);

  machinesThatAreAuthoritativeDnsServers = builtins.map
    (machine: machine // {
      ips = ([ "${config.antibuilding.ipv6Prefix}::${builtins.toString machine.address}" ] ++
        (if machine.staticIp4 != null then [ "${machine.staticIp4}" ] else [ ]) ++
        (if machine.staticIp6 != null then [ "${machine.staticIp6}" ] else [ ]));
    })
    (lib.attrValues
      (lib.filterAttrs (name: machine: machine.authoritativeDns.enable) config.machines));
  primaryServers = lib.filter (machine: machine.authoritativeDns.primary) machinesThatAreAuthoritativeDnsServers;
  serversWithStaticIpv4 = lib.filter (machine: machine.staticIp4 != null) machines;
  serversWithStaticIpv6 = lib.filter (machine: machine.staticIp6 != null) machines;
  thisServer = lib.head (lib.attrValues (lib.filterAttrs (name: machine: name == config.networking.hostName) config.machines));
  grafanaServer = lib.head (lib.attrValues (lib.filterAttrs (name: machine: machine.monitoring.enable) config.machines));
  headscaleServer = lib.head (lib.attrValues (lib.filterAttrs (name: machine: machine.headscale.enable) config.machines));
  birdLgServer = lib.head (lib.attrValues (lib.filterAttrs (name: machine: machine.bird-lg.enable) config.machines));
  routedbitsDn42Server = lib.head (lib.attrValues (lib.filterAttrs (name: machine: machine.routedbitsDn42.enable) config.machines));
in
{
  config.modules.dns.zones = lib.mkIf thisServer.authoritativeDns.enable (
    {
      # Used for infrastructure and internal names
      "antibuild.ing" = ''
        ; grafana
        grafana IN A ${grafanaServer.staticIp4}
        grafana IN AAAA ${grafanaServer.staticIp6}

        ; headscale
        headscale IN A ${headscaleServer.staticIp4}
        headscale IN AAAA ${headscaleServer.staticIp6}

        ; bird looking-glass
        lg IN A ${birdLgServer.staticIp4}
        lg IN AAAA ${birdLgServer.staticIp6}

        ; routedbits peering
        de1.routedbits IN A ${routedbitsDn42Server.staticIp4}
        de1.routedbits IN AAAA ${routedbitsDn42Server.staticIp6}
      ''
      +
      (builtins.concatStringsSep "\n" (
        builtins.map
          (machine: ''
            ; Bird looking-glass proxy record for ${machine.name}
            ${machine.name}.lg IN AAAA ${config.antibuilding.ipv6Prefix}::${builtins.toString machine.address}
          '')
          machines))
      +
      (builtins.concatStringsSep "\n" (
        builtins.map
          (machine: ''
            ; Public ipv4 entry for ${machine.name}
            ${machine.name}.outside IN A ${builtins.toString machine.staticIp4}
          '')
          serversWithStaticIpv4))
      +
      (builtins.concatStringsSep "\n" (
        builtins.map
          (machine: ''
            ; Public ipv6 entry for ${machine.name}
            ${machine.name}.outside IN AAAA ${builtins.toString machine.staticIp6}
          '')
          serversWithStaticIpv6))
      +
      ''
        ; A a record, so there is a record for the root domain
        @ IN A ${(lib.head primaryServers).staticIp4}
      '';

      # Used for my external stuff. Matrix, mail, etc.
      "zebre.us" = ''
        ; Records for matrix/synapse
        @ IN A 167.235.154.30
        element IN A 167.235.154.30
        matrix IN A 167.235.154.30
        turn IN A 167.235.154.30
        @ IN AAAA 2a01:4f8:c0c:d91f::1
        element IN AAAA 2a01:4f8:c0c:d91f::1
        matrix IN AAAA 2a01:4f8:c0c:d91f::1
        turn IN AAAA 2a01:4f8:c0c:d91f::1
      '';



      # I use this domains for hosting random stuff with github pages
      "wirs.ing" = ''
        ; CNAME on the root is apparently not standard. There are probably good reasons for that.
        ; I just added the A and AAAA records for zebreus.github.io manually.
        ; @ IN CNAME zebreus.github.io.
        @	IN A 185.199.108.153
        @	IN A 185.199.109.153
        @	IN A 185.199.110.153
        @	IN A 185.199.111.153
        @	IN AAAA 2606:50c0:8000::153
        @	IN AAAA 2606:50c0:8001::153
        @	IN AAAA 2606:50c0:8002::153
        @	IN AAAA 2606:50c0:8003::153
        ofborg IN CNAME zebreus.github.io.
        search IN CNAME zebreus.github.io.
        second IN CNAME zebreus.github.io.
        coreboot IN CNAME zebreus.github.io.
        _github-pages-challenge-zebreus IN TXT ${quoteTxtEntry "3a57be146a6065e7abbae1a5783afa"}

        besserer IN A 49.13.8.171
        besserer IN AAAA 2a01:4f8:c013:29b1::1
      '';


      # Hosts a badly drawn picture of a unicorn
      "einhorn.jetzt" = ''
        ; CNAME on the root is apparently not standard. There are probably good reasons for that.
        ; I just added the A and AAAA records for zebreus.github.io manually.
        ; @ IN CNAME zebreus.github.io.
        @	IN A 185.199.108.153
        @	IN A 185.199.109.153
        @	IN A 185.199.110.153
        @	IN A 185.199.111.153
        @	IN AAAA 2606:50c0:8000::153
        @	IN AAAA 2606:50c0:8001::153
        @	IN AAAA 2606:50c0:8002::153
        @	IN AAAA 2606:50c0:8003::153
        www IN CNAME zebreus.github.io.
        _github-pages-challenge-zebreus IN TXT ${quoteTxtEntry "039c1f2cef900279d730d61bbf2295"}
        @ IN TXT ${quoteTxtEntry "google-site-verification=N11GiQq5grX82UY2Ik0dn4AQ7NpFd4dl_Sg2G2BYrvU"}
      '';

      # Hosts a now defunct and unfinished project for ai generated shirts
      "generated.fashion" = ''

        @	IN A 76.76.21.21
        www	IN CNAME cname.vercel-dns.com.
        @ IN TXT ${quoteTxtEntry "google-site-verification=6B_Cig2VbMktIY9q13NowVz_5bZ1bQLgSOdFgVqpuzQ"}
      '';

      # Hosts a broken test of a gunjs based blog
      "xn--f87c.cc" = ''
        @	IN A 76.76.21.21
        www	IN CNAME cname.vercel-dns.com.
        testing IN NS ns1.vercel-dns.com.
      '';
    }
  );
}
