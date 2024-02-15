# Adds cli programs to system packages
# Various editors and other tools
{ pkgs, ... }:
{
  # List packages installed in system profile. To search, run:
  environment.systemPackages = with pkgs;
    [
      nixpkgs-fmt
      nix-index
      killall
      htop
      btop
      git
      curl
      usbutils
      pciutils
      wget
      vim
      kakoune
      helix
      s-tui
      stress-ng
      p7zip
      lsof
      tmux
      nmap
      croc
      eza
      rsync
      ffmpeg
      nil
      imagemagick
    ];
}
