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
        @ IN SOA ns1.antibuild.ing. lennart@zebre.us (
                1710209111  ; serial secs since Jan 1 1970
                60      ; refresh (>=60)
                60      ; retry (>=60)
                60      ; expire
                60      ; minimum
                )
        IN  NS ns1.antibuild.ing.
        IN  NS ns2.antibuild.ing.
        ns1 IN	A	167.235.154.30
        ns2 IN	A	192.227.228.220
        ; ns1 IN	AAAA	2a01:4f8:c0c:d91f::1

        ; Records for mail
        mail IN CNAME mail.zebre.us.
        @ IN TXT v=spf1 a:mail.example.com -all
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

  };

  networking.extraHosts = "167.235.154.30 ns1.antibuild.ing ns2.antibuild.ing";

}
