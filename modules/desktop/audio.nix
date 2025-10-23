{ lib, config, ... }: {
  config = lib.mkIf config.machines.${config.networking.hostName}.desktop.enable {
    # # This only enables alsa
    # sound.enable = true;
    # Enable sound with pipewire.
    services.pulseaudio.enable = false;
    services.pulseaudio.zeroconf.discovery.enable = true;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    services.avahi.enable = true;
    # services.avahi.openFirewall = true;

    users.extraGroups.audio.members = [ "lennart" ];
  };
}
