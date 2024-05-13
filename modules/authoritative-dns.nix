{ lib, config, pkgs, ... }:
let
  publicKeys = import ../secrets/public-keys.nix;

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

  machinesThatCanReceiveMail = lib.attrValues (lib.filterAttrs (name: machine: machine.managed) config.machines);

  machinesThatAreAuthoritativeDnsServers = builtins.map
    (machine: machine // {
      ips = ([ "${config.antibuilding.ipv6Prefix}::${builtins.toString machine.address}" ] ++
        (if machine.staticIp4 != null then [ "${machine.staticIp4}" ] else [ ]) ++
        (if machine.staticIp6 != null then [ "${machine.staticIp6}" ] else [ ]));
    })
    (lib.attrValues
      (lib.filterAttrs (name: machine: machine.authoritativeDns.enable) config.machines));
  primaryServers = lib.filter (machine: machine.authoritativeDns.primary) machinesThatAreAuthoritativeDnsServers;
  secondaryServers = lib.filter (machine: machine.authoritativeDns.primary == false) machinesThatAreAuthoritativeDnsServers;
  thisServer = lib.head (lib.attrValues (lib.filterAttrs (name: machine: name == config.networking.hostName) config.machines));

  zones = {
    # Used for infrastructure and internal names
    "antibuild.ing" = ''
      $TTL 60
      $ORIGIN antibuild.ing.
      @ SOA ${(lib.head primaryServers).authoritativeDns.name}.antibuild.ing. lennart.zebre.us. 1710258000 14400 3600 604800 300

      ; Nameservers
      ${lib.concatStringsSep "\n" (lib.concatMap (machine: [
        "@ NS ${machine.authoritativeDns.name}.antibuild.ing." ] ++ 
        (if machine.staticIp4 != null then [ "${machine.authoritativeDns.name} A ${machine.staticIp4}" ] else [ ]) ++
        (if machine.staticIp6 != null then [ "${machine.authoritativeDns.name} AAAA ${machine.staticIp6}" ] else [ ])
      ) machinesThatAreAuthoritativeDnsServers)}

      ; Records for mail
      @ IN TXT ${quoteTxtEntry "v=spf1 a:mail.zebre.us -all"}
      mail IN TXT ${quoteTxtEntry "v=spf1 a:mail.zebre.us -all"}
      _dmarc IN TXT ${quoteTxtEntry "v=DMARC1; p=reject; fo=1; adkim=s; aspf=s; ri=86400; rua=mailto:dmarc-reports@zebre.us; ruf=mailto:dmarc-reports@zebre.us"}
      mail._domainkey IN TXT ${quoteTxtEntry "v=DKIM1; k=rsa; s=email; p=${publicKeys.antibuild_ing_dkim}"}
      @ IN MX 30 mail.zebre.us.
      ; Autodiscovery:
      _submission._tcp IN SRV 0 5 587 mail.zebreu.us.
      _submissions._tcp IN SRV 0 5 465 mail.zebreu.us.
      _imap._tcp IN SRV 0 5 143 mail.zebreu.us.
      _imaps._tcp IN SRV 0 5 993 mail.zebreu.us.

      ; TXT for keyoxide
      @ IN TXT ${quoteTxtEntry "openpgp4fpr:2D53CFEA1AB4017BB327AFE310A46CC3152D49C5"}
    ''
    +
    (builtins.concatStringsSep "\n" (
      builtins.map
        # TODO: Verify that autodiscovery works like this
        (machine: ''
          ; Mail records for ${machine.name}
          _dmarc.${machine.name} TXT ${quoteTxtEntry "v=DMARC1; p=reject; fo=1; adkim=s; aspf=s; ri=86400; rua=mailto:dmarc-reports@zebre.us; ruf=mailto:dmarc-reports@zebre.us"}
          ${machine.name} TXT ${quoteTxtEntry "v=spf1 a:mail.zebre.us -all"}
          mail._domainkey.${machine.name} TXT ${quoteTxtEntry "v=DKIM1; k=rsa; s=email; p=${publicKeys."${machine.name}_dkim"}"}
          ${machine.name} MX 30 mail.zebre.us.
          ; Autodiscovery
          _submission._tcp.${machine.name} SRV 0 5 587 mail.zebreu.us.
          _submissions._tcp.${machine.name} SRV 0 5 465 mail.zebreu.us.
          _imap._tcp.${machine.name} SRV 0 5 143 mail.zebreu.us.
          _imaps._tcp.${machine.name} SRV 0 5 993 mail.zebreu.us.
        '')
        machinesThatCanReceiveMail))
    +
    ''
      ; A a record, so there is a record for the root domain
      @ IN A ${(lib.head primaryServers).staticIp4}
    '';

    # Used for my external stuff. Matrix, mail, etc.
    "zebre.us" = ''
      $TTL 60
      $ORIGIN zebre.us.
      @ IN SOA ns1.antibuild.ing. lennart.zebre.us. (
              1710258000  ; serial secs since Jan 1 1970
              14400        ; refresh (>=60)
              3600        ; retry (>=60)
              604800      ; expire
              300          ; minimum ttl
              )
      @ IN NS ns1.antibuild.ing.
      @ IN NS ns2.antibuild.ing.
      @ IN NS ns3.antibuild.ing.

      ; Records for matrix/synapse
      @ IN A 167.235.154.30
      element IN A 167.235.154.30
      matrix IN A 167.235.154.30
      turn IN A 167.235.154.30
      @ IN AAAA 2a01:4f8:c0c:d91f::1
      element IN AAAA 2a01:4f8:c0c:d91f::1
      matrix IN AAAA 2a01:4f8:c0c:d91f::1
      turn IN AAAA 2a01:4f8:c0c:d91f::1

      ; Records for mail
      mail IN A 192.227.228.220
      @ IN TXT ${quoteTxtEntry "v=spf1 a:mail.zebre.us -all"}
      mail IN TXT ${quoteTxtEntry "v=spf1 a:mail.zebre.us -all"}
      _dmarc IN TXT ${quoteTxtEntry "v=DMARC1; p=reject; fo=1; adkim=s; aspf=s; ri=86400; rua=mailto:dmarc-reports@zebre.us; ruf=mailto:dmarc-reports@zebre.us"}
      mail._domainkey IN TXT ${quoteTxtEntry "v=DKIM1; k=rsa; s=email; p=${publicKeys.zebre_us_dkim}"}
      @ IN MX 30 mail.zebre.us.
      ; Autodiscovery:
      _submission._tcp IN SRV 0 5 587 mail.zebreu.us.
      _submissions._tcp IN SRV 0 5 465 mail.zebreu.us.
      _imap._tcp IN SRV 0 5 143 mail.zebreu.us.
      _imaps._tcp IN SRV 0 5 993 mail.zebreu.us.

      ; TXT for keyoxide
      @ IN TXT ${quoteTxtEntry "openpgp4fpr:2D53CFEA1AB4017BB327AFE310A46CC3152D49C5"}
    '';

    # My old email server lived here. Now it's just a redirect to the new one
    "madmanfred.com" = ''
      $TTL 60
      $ORIGIN madmanfred.com.
      @ IN SOA ns1.antibuild.ing. lennart.zebre.us. (
              1710258000  ; serial secs since Jan 1 1970
              14400        ; refresh (>=60)
              3600        ; retry (>=60)
              604800      ; expire
              300          ; minimum ttl
              )
      @ IN NS ns1.antibuild.ing.
      @ IN NS ns2.antibuild.ing.
      @ IN NS ns3.antibuild.ing.

      ; Records for mail
      @ IN TXT ${quoteTxtEntry "v=spf1 a:mail.zebre.us -all"}
      mail IN TXT ${quoteTxtEntry "v=spf1 a:mail.zebre.us -all"}
      _dmarc IN TXT ${quoteTxtEntry "v=DMARC1; p=reject; fo=1; adkim=s; aspf=s; ri=86400; rua=mailto:dmarc-reports@zebre.us; ruf=mailto:dmarc-reports@zebre.us"}
      mail._domainkey IN TXT ${quoteTxtEntry "v=DKIM1; k=rsa; s=email; p=${publicKeys.madmanfred_com_dkim}"}
      @ IN MX 30 mail.zebre.us.
      ; Autodiscovery:
      _submission._tcp IN SRV 0 5 587 mail.zebreu.us.
      _submissions._tcp IN SRV 0 5 465 mail.zebreu.us.
      _imap._tcp IN SRV 0 5 143 mail.zebreu.us.
      _imaps._tcp IN SRV 0 5 993 mail.zebreu.us.

      ; TXT for keyoxide
      @ IN TXT ${quoteTxtEntry "openpgp4fpr:2D53CFEA1AB4017BB327AFE310A46CC3152D49C5"}
    '';

    # I use this domains for hosting random stuff with github pages
    "wirs.ing" = ''
      $TTL 60
      $ORIGIN wirs.ing.
      @ IN SOA ns1.antibuild.ing. lennart.zebre.us. (
              1710258000  ; serial secs since Jan 1 1970
              14400       ; refresh (>=60)
              3600        ; retry (>=60)
              604800      ; expire
              300         ; minimum ttl
              )
      @ IN NS ns1.antibuild.ing.
      @ IN NS ns2.antibuild.ing.
      @ IN NS ns3.antibuild.ing.

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
      _github-pages-challenge-zebreus IN TXT ${quoteTxtEntry "3a57be146a6065e7abbae1a5783afa"}

      besserer IN A 49.13.8.171
      besserer IN AAAA 2a01:4f8:c013:29b1::1

      ; TXT for keyoxide
      @ IN TXT ${quoteTxtEntry "openpgp4fpr:2D53CFEA1AB4017BB327AFE310A46CC3152D49C5"}
    '';

    # My old matrix server
    "cicen.net" = ''
      $TTL 60
      $ORIGIN cicen.net.
      @ IN SOA ns1.antibuild.ing. lennart.zebre.us. (
              1710258000  ; serial secs since Jan 1 1970
              14400       ; refresh (>=60)
              3600        ; retry (>=60)
              604800      ; expire
              300         ; minimum ttl
              )
      @ IN NS ns1.antibuild.ing.
      @ IN NS ns2.antibuild.ing.
      @ IN NS ns3.antibuild.ing.

      ; TXT for keyoxide
      @ IN TXT ${quoteTxtEntry "openpgp4fpr:2D53CFEA1AB4017BB327AFE310A46CC3152D49C5"}
    '';

    # I use this domain for testing
    "del.blue" = ''
      $TTL 60
      $ORIGIN del.blue.
      @ IN SOA ns1.antibuild.ing. lennart.zebre.us. (
              1710258000  ; serial secs since Jan 1 1970
              14400       ; refresh (>=60)
              3600        ; retry (>=60)
              604800      ; expire
              300         ; minimum ttl
              )
      @ IN NS ns1.antibuild.ing.
      @ IN NS ns2.antibuild.ing.
      @ IN NS ns3.antibuild.ing.

      ; TXT for keyoxide
      @ IN TXT ${quoteTxtEntry "openpgp4fpr:2D53CFEA1AB4017BB327AFE310A46CC3152D49C5"}
    '';

    # Hosts a badly drawn picture of a unicorn
    "einhorn.jetzt" = ''
      $TTL 60
      $ORIGIN einhorn.jetzt.
      @ IN SOA ns1.antibuild.ing. lennart.zebre.us. (
              1710258000  ; serial secs since Jan 1 1970
              14400       ; refresh (>=60)
              3600        ; retry (>=60)
              604800      ; expire
              300         ; minimum ttl
              )
      @ IN NS ns1.antibuild.ing.
      @ IN NS ns2.antibuild.ing.
      @ IN NS ns3.antibuild.ing.

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

      ; TXT for keyoxide
      @ IN TXT ${quoteTxtEntry "openpgp4fpr:2D53CFEA1AB4017BB327AFE310A46CC3152D49C5"}
    '';

    # Hosts a now defunct and unfinished project for ai generated shirts
    "generated.fashion" = ''
      $TTL 60
      $ORIGIN generated.fashion.
      @ IN SOA ns1.antibuild.ing. lennart.zebre.us. (
              1710258000  ; serial secs since Jan 1 1970
              14400       ; refresh (>=60)
              3600        ; retry (>=60)
              604800      ; expire
              300         ; minimum ttl
              )
      @ IN NS ns1.antibuild.ing.
      @ IN NS ns2.antibuild.ing.
      @ IN NS ns3.antibuild.ing.

      @	IN A 76.76.21.21
      www	IN CNAME cname.vercel-dns.com.
      @ IN TXT ${quoteTxtEntry "google-site-verification=6B_Cig2VbMktIY9q13NowVz_5bZ1bQLgSOdFgVqpuzQ"}

      ; TXT for keyoxide
      @ IN TXT ${quoteTxtEntry "openpgp4fpr:2D53CFEA1AB4017BB327AFE310A46CC3152D49C5"}
    '';

    # Hosts a broken test of a gunjs based blog
    "xn--f87c.cc" = ''
      $TTL 60
      $ORIGIN xn--f87c.cc.
      @ IN SOA ns1.antibuild.ing. lennart.zebre.us. (
              1710258000  ; serial secs since Jan 1 1970
              14400       ; refresh (>=60)
              3600        ; retry (>=60)
              604800      ; expire
              300         ; minimum ttl
              )
      @ IN NS ns1.antibuild.ing.
      @ IN NS ns2.antibuild.ing.
      @ IN NS ns3.antibuild.ing.

      @	IN A 76.76.21.21
      www	IN CNAME cname.vercel-dns.com.
      testing IN NS ns1.vercel-dns.com.

      ; TXT for keyoxide
      @ IN TXT ${quoteTxtEntry "openpgp4fpr:2D53CFEA1AB4017BB327AFE310A46CC3152D49C5"}
    '';

    # Maybe I will use this for an url shortener or something. nothing for now
    "zeb.rs" = ''
      $TTL 60
      $ORIGIN zeb.rs.
      @ IN SOA ns1.antibuild.ing. lennart.zebre.us. (
              1710258000  ; serial secs since Jan 1 1970
              14400       ; refresh (>=60)
              3600        ; retry (>=60)
              604800      ; expire
              300         ; minimum ttl
              )
      @ IN NS ns1.antibuild.ing.
      @ IN NS ns2.antibuild.ing.
      @ IN NS ns3.antibuild.ing.

      ; TXT for keyoxide
      @ IN TXT ${quoteTxtEntry "openpgp4fpr:2D53CFEA1AB4017BB327AFE310A46CC3152D49C5"}
    '';
    # 
  };

  knotZonesEnv = pkgs.buildEnv {
    name = "knot-zones";
    paths = (lib.mapAttrsToList (name: value: pkgs.writeTextDir "${name}.zone" value) zones);
  };
in
{
  config = lib.mkIf thisServer.authoritativeDns.enable
    {
      age.secrets.knot_transport_key = {
        file = ../secrets/knot_transport_key.age;
        owner = "knot";
        group = "knot";
        mode = "0400";
      };

      networking.firewall.allowedTCPPorts = [ 53 ];
      networking.firewall.allowedUDPPorts = [ 53 ];
      services.knot = {
        enable = true;
        keyFiles = [ config.age.secrets.knot_transport_key.path ];
        settings =
          {
            remote = builtins.map
              # TODO: Verify that autodiscovery works like this
              (machine: {
                id = machine.name;
                key = "knot_transfer_key";
                address = builtins.map (ip: "${ip}@53") machine.ips;
              })
              machinesThatAreAuthoritativeDnsServers;

            server = {
              listen = [ "0.0.0.0@53" "::@53" ];
            };
            log.syslog.any = "info";
            template.default = {
              storage = knotZonesEnv;
              dnssec-signing = true;

              # Input-only zone files
              # https://www.knot-dns.cz/docs/2.8/html/operation.html#example-3
              # prevents modification of the zonefiles, since the zonefiles are immutable
              zonefile-sync = -1;
              zonefile-load = "difference";
              journal-content = "changes";
            };
            acl = [
              {
                id = "transfer_antibuilding";
                key = "knot_transfer_key";
                address = builtins.concatMap (machine: machine.ips) (secondaryServers ++ primaryServers);
                # [ "${config.antibuilding.ipv6Prefix}::/64" "167.235.154.30" "49.13.8.171/32" "192.227.228.220/32" ];
                action = [ "transfer" ];
              }
              {
                id = "notify_antibuilding";
                key = "knot_transfer_key";
                address = builtins.concatMap (machine: machine.ips) (secondaryServers ++ primaryServers);
                action = [ "notify" ];
              }
            ];
            policy = [
              {
                id = "normal-signatures";
                signing-threads = 2;
                algorithm = "ECDSAP256SHA256";
                zsk-lifetime = "1d";
                ksk-lifetime = "0";
                reproducible-signing = true;
              }
            ];

            zone = (lib.mapAttrs
              (name: value: (if thisServer.authoritativeDns.primary then {
                file = "${name}.zone";
                notify = builtins.map (machine: machine.name) secondaryServers;
                acl = "transfer_antibuilding";
                dnssec-signing = true;
                dnssec-policy = "normal-signatures";
              } else {
                file = "${name}.zone";
                master = builtins.map (machine: machine.name) primaryServers;
                acl = "notify_antibuilding";
                dnssec-signing = false;
              }))
              zones);
          };
      };
    };
}
