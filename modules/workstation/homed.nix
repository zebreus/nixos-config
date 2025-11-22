{ lib, config, ... }: {
  config = lib.mkIf config.machines.${config.networking.hostName}.workstation.enable {
    # services.homed.enable = true;

    # # This gives 497a root on my machine
    # age.secrets."497a_homed" = {
    #   file = ../../secrets/497a_homed.age;
    #   path = "/var/lib/systemd/home/497a.public";
    # };
  };
}
