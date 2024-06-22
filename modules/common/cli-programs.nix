# Adds cli programs to system packages
# Various editors and other tools
{ lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs;
    [
      nixpkgs-fmt
      nixfmt-rfc-style
      nix-index
      killall
      htop
      btop
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
      agenix
      age
      mtr
      inetutils
      dnsutils
      iputils
    ];
  environment.shellAliases = {
    sl = "${lib.getExe pkgs.sl} -w -5 -e";
  };
}
