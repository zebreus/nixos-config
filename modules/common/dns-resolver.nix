{ config, ... }: {

  services.resolved = {
    enable = true;
    fallbackDns = [
      "9.9.9.9"
      "1.1.1.1"
    ];
    extraConfig = ''
      DNS=[::1]:54
      DNSStubListener=yes
    '';
  };
  networking.resolvconf.useLocalResolver = true;

  services.pdns-recursor =
    {
      enable = true;
      dns = {
        port = 54;
        allowFrom = [
          "127.0.0.0/8"
          "::1/128"
        ];
      };
      # dont-query = 127.0.0.0/8, 192.168.0.0/16, ::1/128, fe80::/10
      settings = {
        server-id = config.networking.hostName;
        query-local-address = [
          "::"
          "0.0.0.0"
        ];
        # Default values from https://docs.powerdns.com/recursor/settings.html#dont-query
        # Minus dn42 ranges
        dont-query = [
          "127.0.0.0/8"
          "10.0.0.0/8"
          "100.64.0.0/10"
          "169.254.0.0/16"
          "192.168.0.0/16"
          "172.16.0.0/12"
          "::1/128"
          "fc00::/7"
          "fe80::/10"
          "0.0.0.0/8"
          "192.0.0.0/24"
          "192.0.2.0/24"
          "198.51.100.0/24"
          "203.0.113.0/24"
          "240.0.0.0/4"
          "::/96"
          "::ffff:0:0/96"
          "100::/64"
          "2001:db8::/32"
          "!172.20.0.0/14"
          "!fc00::/7"
        ];
        # loglevel = "7";
        # trace = "yes";
      };
      serveRFC1918 = false;
      # TODO: Generate this automatically from the dn42 registry
      luaConfig = ''
        -- dn42 DNSSEC trust anchors
        -- https://git.dn42.dev/dn42/registry/src/branch/master/data/dns/dn42
        addTA('dn42.', "64441 10 2 6dadda00f5986bd26fe4f162669742cf7eba07d212b525acac9840ee06cb2799")
        addTA('dn42.', "3096 10 2 b7c687a99bee60e172ea439bd2d3087b1d970916575db9c1cb591b7ee15d8cb1")
        -- https://git.dn42.dev/dn42/registry/src/branch/master/data/inetnum/172.20.0.0_16
        addTA('20.172.in-addr.arpa.', "64441 10 2 616c149633e93d963b0e8f738719630ea0a09f4aabe211b1fbb8fc9f51304027")
        addTA('20.172.in-addr.arpa.', "3096 10 2 6adf85efddf223c8747f1816b12b62feea0b9b1bdb65e7c809202f890a33740d")
        -- https://git.dn42.dev/dn42/registry/src/branch/master/data/inetnum/172.21.0.0_16
        addTA('21.172.in-addr.arpa.', "64441 10 2 4cc085716ba83f18df1a7fb9f9479d10327e3d30e222c7a197109c7560ae0368")
        addTA('21.172.in-addr.arpa.', "3096 10 2 506fd7f34aaad4df1b6cfa56fe8c00e157b1c32551c981def0c5fd8f65ab14ac")
        -- https://git.dn42.dev/dn42/registry/src/branch/master/data/inetnum/172.22.0.0_16
        addTA('22.172.in-addr.arpa.', "64441 10 2 383a8c2714d3da76f58cee4c54566566b336b2dfa219b965f7cb706d71c54356")
        addTA('22.172.in-addr.arpa.', "3096 10 2 5437ab49f1cd947d41c585c2cc9c357323013391b0e5f94784f99175142c3260")
        -- https://git.dn42.dev/dn42/registry/src/branch/master/data/inetnum/172.23.0.0_16
        addTA('23.172.in-addr.arpa.', "64441 10 2 e91c0281e705317968c76689e4f36bf2207c90bdfaad071693bb9a999d15778f")
        addTA('23.172.in-addr.arpa.', "3096 10 2 631b00ba00cf80a8300b356bcca2fde4c844f6ff707a2d98b4518c72e0643467")
        -- https://git.dn42.dev/dn42/registry/src/branch/master/data/inet6num/fd00::_8
        addTA('d.f.ip6.arpa.', "64441 10 2 9057500a3b6e09bf45a60ed8891f2e649c6812d5d149c45a3c560fa0a6195c49")
        addTA('d.f.ip6.arpa.', "3096 10 2 23fb364c82e6ed1c30b18c635f58dca58bbeb2e069bbd9d90ab9a90f66b948d2")
        -- https://git.dn42.dev/dn42/registry/src/branch/master/data/inetnum/172.31.0.0_16
        addTA('31.172.in-addr.arpa.', "64441 10 2 5f668f3083d65650ab5c4e9fccdddd0c8108e0fa4be39e161e6a58d1741c5b2d")
        addTA('31.172.in-addr.arpa.', "3096 10 2 4ab3c242fdfa6d84cbe83d5c9b0f9b431c6974dd18db32d08a2599ab1b816465")
        -- https://git.dn42.dev/dn42/registry/src/branch/master/data/inetnum/10.0.0.0_8
        addTA('10.in-addr.arpa.', "64441 10 2 8a39e9df85a73f1982e43c9139e095e8548451d2048d92c2703869ef8bfebbb4")
        addTA('10.in-addr.arpa.', "3096 10 2 1fa3673dc2cf9ffa82b429bf25405b44931460b7263a081d586cc61f003a10a2")

        -- zone to cache
        zoneToCache(".", "url", "https://www.internic.net/domain/root.zone", { refreshPeriod = 0 })
      '';

      forwardZones =
        let
          # k.delegation-servers.dn42.
          # b.delegation-servers.dn42.
          # j.delegation-servers.dn42.
          # l.delegation-servers.dn42.
          dn42roots = "fdcf:8538:9ad5:1111::2;fd42:4242:2601:ac53::1;fd42:5d71:219:0:216:3eff:fe1e:22d6;fd86:bad:11b7:53::1";
        in
        {
          "dn42" = dn42roots;
          "20.172.in-addr.arpa" = dn42roots;
          "21.172.in-addr.arpa" = dn42roots;
          "22.172.in-addr.arpa" = dn42roots;
          "23.172.in-addr.arpa" = dn42roots;
          "10.in-addr.arpa" = dn42roots;
          "d.f.ip6.arpa" = dn42roots;
        };
    };
}
