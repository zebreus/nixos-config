{ lib, config, pkgs, ... }: {
  config = lib.mkIf config.modules.desktop.enable {
    fonts = {
      enableDefaultPackages = true;
      packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk
        noto-fonts-emoji
        liberation_ttf
        fira-code
        fira-code-symbols
        mplus-outline-fonts.githubRelease
        dina-font
        proggyfonts
        monaspace
      ];

      fontconfig = {
        defaultFonts = {
          monospace = [ "Monaspace Neon" ];
        };
      };
    };
  };
}
