{ lib, config, ... }:
let
  inherit (import ./helper.nix { inherit lib; }) quoteTxtEntry;

  thisServer = lib.head (lib.attrValues (lib.filterAttrs (name: machine: name == config.networking.hostName) config.machines));
in
{
  config.modules.dns.zones = lib.mkIf thisServer.authoritativeDns.enable (
    {
      # I use this domains for hosting random stuff with github pages
      "wirs.ing" = ''
        ; various github pages
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
        custom IN CNAME zebreus.github.io.
        rudelshopping IN CNAME zebreus.github.io.
        _github-pages-challenge-zebreus IN TXT ${quoteTxtEntry "3a57be146a6065e7abbae1a5783afa"}
      '';

      # I use this domains for hosting random stuff with github pages
      "essen.jetzt" = ''
        ; various github pages
        katzenohren IN CNAME zebreus.github.io.
        _github-pages-challenge-zebreus IN TXT ${quoteTxtEntry "efa5b694f67911424ba8ab8cd50321"}
      '';

      # I use this domains for hosting random stuff with github pages
      "skyfeedlol.lol" = ''
        ; various github pages
        @	IN A 185.199.108.153
        @	IN A 185.199.109.153
        @	IN A 185.199.110.153
        @	IN A 185.199.111.153
        @	IN AAAA 2606:50c0:8000::153
        @	IN AAAA 2606:50c0:8001::153
        @	IN AAAA 2606:50c0:8002::153
        @	IN AAAA 2606:50c0:8003::153
        www IN CNAME zebreus.github.io.
        _github-pages-challenge-zebreus IN TXT ${quoteTxtEntry "0f60074220ca67788318fee0ceab68"}

        monitoring.indexer IN A 188.34.166.167
        pgadmin.indexer IN A 188.34.166.167
        dev.indexer IN A 157.90.147.232
      '';

      # I use this domains for hosting random stuff with github pages
      "rudelb.link" = ''
        ; deno deploy
        @ IN A 34.120.54.55
        @ IN AAAA 2600:1901:0:6d85::
        _acme-challenge IN CNAME 61e1a5bc5ccdb1942ca99c10._acme.deno.dev.

        _github-pages-challenge-zebreus IN TXT ${quoteTxtEntry "35f0ff4e1cb553289300913bdcd0cf"}
      '';

      # Hosts a badly drawn picture of a unicorn
      "einhorn.jetzt" = ''
        ; github pages
        _github-pages-challenge-zebreus IN TXT ${quoteTxtEntry "039c1f2cef900279d730d61bbf2295"}
        @	IN A 185.199.108.153
        @	IN A 185.199.109.153
        @	IN A 185.199.110.153
        @	IN A 185.199.111.153
        @	IN AAAA 2606:50c0:8000::153
        @	IN AAAA 2606:50c0:8001::153
        @	IN AAAA 2606:50c0:8002::153
        @	IN AAAA 2606:50c0:8003::153
        www IN CNAME zebreus.github.io.

        ; google site verification
        @ IN TXT ${quoteTxtEntry "google-site-verification=N11GiQq5grX82UY2Ik0dn4AQ7NpFd4dl_Sg2G2BYrvU"}
      '';

      # Hosts a now defunct and unfinished project for ai generated shirts
      "generated.fashion" = ''
        ; generated.fashion on hosted on vercel
        @	IN A 76.76.21.21
        www	IN CNAME cname.vercel-dns.com.

        ; google site verification
        @ IN TXT ${quoteTxtEntry "google-site-verification=6B_Cig2VbMktIY9q13NowVz_5bZ1bQLgSOdFgVqpuzQ"}
      '';

      # Hosts a broken test of a gunjs based blog
      "xn--f87c.cc" = ''
        ; blog test on vercel
        @	IN A 76.76.21.21
        www	IN CNAME cname.vercel-dns.com.
        testing IN NS ns1.vercel-dns.com.
      '';

      "darmfest.de" = ''
        ; github pages
        # _github-pages-challenge-zebreus IN TXT ${quoteTxtEntry "039c1f2cef900279d730d61bbf2295"}
        @	IN A 185.199.108.153
        @	IN A 185.199.109.153
        @	IN A 185.199.110.153
        @	IN A 185.199.111.153
        @	IN AAAA 2606:50c0:8000::153
        @	IN AAAA 2606:50c0:8001::153
        @	IN AAAA 2606:50c0:8002::153
        @	IN AAAA 2606:50c0:8003::153
        www IN CNAME darmfest.de.

        ; google site verification
        @ IN TXT ${quoteTxtEntry "google-site-verification=MALeUxuBug7rgptrtijQWhfIWCJ_AraTZwS00xUnAXQ"}
      '';
    }
  );
}
