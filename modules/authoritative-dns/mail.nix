{ lib, config, ... }:
let
  publicKeys = import ../../secrets/public-keys.nix;
  inherit (import ./helper.nix { inherit lib; }) quoteTxtEntry;

  thisServer = config.machines.${config.networking.hostName};

  machines = lib.attrValues config.machines;
  machinesThatCanReceiveMail = builtins.filter (machine: machine.managed) machines;

  mailServer = builtins.head (builtins.filter (machine: machine.mailServer.enable) machines);
in
{
  config.modules.dns.zones = lib.mkIf thisServer.authoritativeDns.enable ({
    # Used for infrastructure and internal names
    "antibuild.ing" = ''
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
        machinesThatCanReceiveMail));

    # Used for my external stuff. Matrix, mail, etc.
    "zebre.us" = ''
      ; Main mail entry
      mail IN A ${mailServer.staticIp4}
      mail IN AAAA ${mailServer.staticIp6}

      ; Records for mail
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

    # My old email server lived here. Now it's just a redirect to the new one
    "madmanfred.com" = ''
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
  });

}
