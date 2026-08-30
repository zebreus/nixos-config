{ lib, config, ... }: {
  config = lib.mkIf config.meta.self.workstation.enable {
    # services.homed.enable = true;

    # # This gives 497a root on my machine
    # age.secrets."497a_homed" = {
    #   path = "/var/lib/systemd/home/497a.public";
    # };
  };
}
