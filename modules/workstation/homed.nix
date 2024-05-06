{ lib, config, ... }: {
  config = lib.mkIf config.modules.workstation.enable {
    services.homed.enable = true;
  };

  age.secrets."497a_homed" = {
        file = ../../secrets + "/497a_homed.age";
        path = "/var/lib/systemd/home/497a.public";
  };
}
