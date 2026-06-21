{ lib, config, ... }: {
  config = lib.mkIf config.meta.self.desktop.enable {
    nixpkgs.config.allowUnfree = true;

    # Enable steam
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    };
  };
}
