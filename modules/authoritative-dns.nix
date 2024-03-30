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

  zones = {
    "antibuild.ing" = ''
      $TTL 60
      $ORIGIN antibuild.ing.
      @       SOA     ns1.antibuild.ing. lennart.zebre.us. 1710252096 14400 3600 604800 300
      @       NS      ns1.antibuild.ing.
      @       NS      ns2.antibuild.ing.
      @       NS      ns3.antibuild.ing.
      ns1     A       167.235.154.30
      ns2     A       49.13.8.171
      ns3     A       192.227.228.220
      ns1     AAAA    2a01:4f8:c0c:d91f::1
      ns2     AAAA    2a01:4f8:c013:29b1::1
    ''
    + (builtins.concatStringsSep "\n" (
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
        machinesThatCanReceiveMail));

    "zebre.us" = ''
      $TTL 60
      $ORIGIN zebre.us.
      @ IN SOA ns1.antibuild.ing. lennart.zebre.us. (
              1710252096  ; serial secs since Jan 1 1970
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
    '';

    "madmanfred.com" = ''
      $TTL 60
      $ORIGIN madmanfred.com.
      @ IN SOA ns1.antibuild.ing. lennart.zebre.us. (
              1710252096  ; serial secs since Jan 1 1970
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
    '';
  };

  knotZonesEnv = pkgs.buildEnv {
    name = "knot-zones";
    paths = lib.mapAttrsToList (name: value: pkgs.writeTextDir "${name}.zone" value) zones;
  };
in
{
  options.modules.authoritative_dns =
    {
      enable = lib.mkEnableOption "Enable the authoritative DNS server on port 53";
    };

  config = lib.mkIf config.modules.authoritative_dns.enable {
    networking.firewall.allowedTCPPorts = [ 53 ];
    networking.firewall.allowedUDPPorts = [ 53 ];
    services.knot = {
      enable = true;
      settings = {
        server = {
          listen = [ "0.0.0.0@53" "::1@53" ];
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
        zone = lib.mapAttrs (name: value: { file = "${name}.zone"; }) zones;
      };
    };
  };
}
