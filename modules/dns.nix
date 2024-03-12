{ lib, ... }:
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
                1710252091  ; serial secs since Jan 1 1970
                7200        ; refresh (>=60)
                3600        ; retry (>=60)
                604800      ; expire
                60          ; minimum ttl
                )
        @ IN NS ns1.antibuild.ing.
        @ IN NS ns2.antibuild.ing.
        ns1 IN A 167.235.154.30
        ns2 IN A 192.227.228.220
        ; ns1 IN AAAA 2a01:4f8:c0c:d91f::1

        ; Records for mail
        mail IN CNAME mail.zebre.us.
        _dmarc.erms IN TXT ${quoteTxtEntry "v=DMARC1; p=none"}
        _dmarc.kappril IN TXT ${quoteTxtEntry "v=DMARC1; p=none"}
        _dmarc.kashenblade IN TXT ${quoteTxtEntry "v=DMARC1; p=none"}
        _dmarc.sempriaq IN TXT ${quoteTxtEntry "v=DMARC1; p=none"}
        erms IN TXT ${quoteTxtEntry "v=spf1 a:mail.zebre.us ip6:fd10:2030::0/64 mx a ptr -all"}
        kappril IN TXT ${quoteTxtEntry "v=spf1 a:mail.zebre.us ip6:fd10:2030::0/64 mx a ptr -all"}
        kashenblade IN TXT ${quoteTxtEntry "v=spf1 a:mail.zebre.us ip6:fd10:2030::0/64 mx a ptr -all"}
        sempriaq IN TXT ${quoteTxtEntry "v=spf1 a:mail.zebre.us ip6:fd10:2030::0/64 mx a ptr -all"}
        mail._domainkey.erms IN TXT ${quoteTxtEntry "v=DKIM1; k=rsa; s=email; p=${publicKeys.erms_dkim}"}
        mail._domainkey.kappril IN TXT ${quoteTxtEntry "v=DKIM1; k=rsa; s=email; p=${publicKeys.kappril_dkim}"}
        mail._domainkey.kashenblade IN TXT ${quoteTxtEntry "v=DKIM1; k=rsa; s=email; p=${publicKeys.kashenblade_dkim}"}
        mail._domainkey.sempriaq IN TXT ${quoteTxtEntry "v=DKIM1; k=rsa; s=email; p=${publicKeys.sempriaq_dkim}"}


        * IN MX 50 mail.zebre.us.
        erms IN MX 30 mail.zebre.us.
        kappril IN MX 30 mail.zebre.us.
        kashenblade IN MX 30 mail.zebre.us.
        sempriaq IN MX 30 mail.zebre.us.
      '';
    };

    zones."zebre.us" = {
      # DNSSEC is currently broken
      # TODO: Fix upstream
      dnssec = false;
      data = ''
        $TTL 60
        $ORIGIN zebre.us.
        @ IN SOA ns1.antibuild.ing. lennart.zebre.us. (
                1710252091  ; serial secs since Jan 1 1970
                7200        ; refresh (>=60)
                3600        ; retry (>=60)
                604800      ; expire
                60          ; minimum ttl
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
        _submission._tcp.zebre.us. 86400 IN SRV 0 5 587 mail.zebreu.us.
        _submissions._tcp.zebre.us. 86400 IN SRV 0 5 465 mail.zebreu.us.
        _imap._tcp.zebre.us. 86400 IN SRV 0 5 143 mail.zebreu.us.
        _imaps._tcp.zebre.us. 86400 IN SRV 0 5 993 mail.zebreu.us.
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
