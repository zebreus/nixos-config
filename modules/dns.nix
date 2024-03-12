{ lib, config, ... }:
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

  machinesThatCanReceiveMail = (lib.attrValues (lib.filterAttrs (name: machine: machine.managed) config.machines));
in
{
  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
  services.nsd = {
    verbosity = 3;
    enable = true;
    interfaces = [ "0.0.0.0" ];
    zones."antibuild.ing" = {
      # DNSSEC is currently broken
      # TODO: Fix upstream
      dnssec = false;
      data = ''
        $TTL 60
        $ORIGIN antibuild.ing.
        @ IN SOA ns1.antibuild.ing. lennart.zebre.us. (
                1710252093  ; serial secs since Jan 1 1970
                14400        ; refresh (>=60)
                3600        ; retry (>=60)
                604800      ; expire
                300          ; minimum ttl
                )
        @ IN NS ns1.antibuild.ing.
        @ IN NS ns2.antibuild.ing.
        ns1 IN A 167.235.154.30
        ns2 IN A 192.227.228.220
        ; ns1 IN AAAA 2a01:4f8:c0c:d91f::1
        
      '' + (builtins.concatStringsSep "\n" (
        builtins.map
          # TODO: Verify that autodiscovery works like this
          (machine: ''
            ; Mail records for ${machine.name}
            _dmarc.${machine.name} IN TXT ${quoteTxtEntry "v=DMARC1; p=none; rua=mailto:dmarc-reports@zebre.us; ruf=mailto:dmarc-reports@zebre.us; fo=1"}
            ${machine.name} IN TXT ${quoteTxtEntry "v=spf1 +ip6:${config.antibuilding.ipv6Prefix}::0/64 +a:mail.zebre.us +mx +a -all"}
            mail._domainkey.${machine.name} IN TXT ${quoteTxtEntry "v=DKIM1; k=rsa; s=email; p=${publicKeys."${machine.name}_dkim"}"}
            ${machine.name} IN MX 30 mail.zebre.us.
            ; Autodiscovery
            _submission._tcp.${machine.name} IN SRV 0 5 587 mail.zebreu.us.
            _submissions._tcp.${machine.name} IN SRV 0 5 465 mail.zebreu.us.
            _imap._tcp.${machine.name} IN SRV 0 5 143 mail.zebreu.us.
            _imaps._tcp.${machine.name} IN SRV 0 5 993 mail.zebreu.us.
          '')
          machinesThatCanReceiveMail));
    };

    zones."zebre.us" = {
      # DNSSEC is currently broken
      # TODO: Fix upstream
      dnssec = false;
      data = ''
        $TTL 60
        $ORIGIN zebre.us.
        @ IN SOA ns1.antibuild.ing. lennart.zebre.us. (
                1710252093  ; serial secs since Jan 1 1970
                14400        ; refresh (>=60)
                3600        ; retry (>=60)
                604800      ; expire
                300          ; minimum ttl
                )
        @ IN NS ns1.antibuild.ing.
        @ IN NS ns2.antibuild.ing.

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
        _dmarc IN TXT ${quoteTxtEntry "v=DMARC1; p=none"}
        mail._domainkey IN TXT ${quoteTxtEntry "v=DKIM1; k=rsa; s=email; p=${publicKeys.zebre_us_dkim}"}
        @ IN MX 30 mail.zebre.us.
        ; Autodiscovery:
        _submission._tcp IN SRV 0 5 587 mail.zebreu.us.
        _submissions._tcp IN SRV 0 5 465 mail.zebreu.us.
        _imap._tcp IN SRV 0 5 143 mail.zebreu.us.
        _imaps._tcp IN SRV 0 5 993 mail.zebreu.us.
      '';
    };

  };

  # I dont think this is necessary
  # TODO: Remove
  networking.hosts = {
    "167.235.154.30" = [ "ns1.antibuild.ing" ];
    "2a01:4f8:c0c:d91f::1" = [ "ns1.antibuild.ing" ];
    "192.227.228.220" = [ "ns2.antibuild.ing" ];
  };
}
