{ lib, config, ... }: {
  config = lib.mkIf config.machines.${config.networking.hostName}.desktop.enable {
    # # This only enables alsa
    # sound.enable = true;
    # Enable sound with pipewire.
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    users.extraGroups.audio.members = [ "lennart" ];
  };
}
