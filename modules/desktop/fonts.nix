{ lib, config, pkgs, ... }: {
  config = lib.mkIf config.machines.${config.networking.hostName}.desktop.enable {
    fonts = {
      enableDefaultPackages = true;
      packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        liberation_ttf
        fira-code
        fira-code-symbols
        mplus-outline-fonts.githubRelease
        dina-font
        proggyfonts
        monaspace
        corefonts
        vista-fonts
        carlito
      ];

      fontconfig = {
        defaultFonts = {
          monospace = [ "Monaspace Neon" ];
        };
      };
    };
  };
}
