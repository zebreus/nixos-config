{ pkgs, lib, ... }: {


  services.udev.extraRules =
    let
      mkRule = as: lib.concatStringsSep ", " as;
      mkRules = rs: lib.concatStringsSep "\n" rs;
    in
    mkRules ([
      (mkRule [
        ''ACTION=="add|change"''
        ''SUBSYSTEM=="block"''
        ''KERNEL=="sd[a-z]"''
        ''ATTR{queue/rotational}=="1"''
        ''RUN+="${pkgs.hdparm}/bin/hdparm -B 90 -S 2 /dev/%k"''
      ])
    ]);

  services.autotierfs = {
    enable = true;
    settings = {
      "/mnt/autotier" = {
        Global = {
          "Log Level" = 2;
          "Tier Period" = 120;
          "Copy Buffer Size" = "1024MiB";
          "Strict Period" = "true";
        };
        "Tier 1" = {
          Path = "/mnt/ssd";
          Quota = "2GiB";
        };
        "Tier 2" = {
          Path = "/mnt/alpha";
          Quota = "2GiB";
        };
        "Tier 3" = {
          Path = "/mnt/beta";
          Quota = "2GiB";
        };
        "Tier 4" = {
          Path = "/mnt/gamma";
          Quota = "2GiB";
        };
        "Tier 5" = {
          Path = "/mnt/delta";
          Quota = "100%";
        };
      };
    };
  };
}
