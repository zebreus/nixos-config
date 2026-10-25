import ../../helpers/meta-service.nix "mail" ({ lib, ... }: {
  cardinality = "atMostOne";
  config.baseDomain = lib.mkOption {
    type = lib.types.str;
    description = ''
      Base domain for the mail server. You need to setup the DNS records according to the
      setup guide at https://nixos-mailserver.readthedocs.io/en/latest/setup-guide.html
      and https://nixos-mailserver.readthedocs.io/en/latest/autodiscovery.html. Also add
      an additional SPF record for the mail subdomain.
    '';
  };
})
