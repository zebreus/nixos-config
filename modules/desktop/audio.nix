{ lib, config, ... }: {
  config = lib.mkIf config.modules.desktop.enable {
    # Enable sound with pipewire.
    sound.enable = true;
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
