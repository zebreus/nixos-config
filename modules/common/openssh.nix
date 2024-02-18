{ pkgs, config, lib, ... }:
let
  motd = pkgs.stdenv.mkDerivation {
    name = "motd";
    src = null;
    phases = "installPhase";
    nativeBuildInputs = [ pkgs.figlet pkgs.toilet ];
    installPhase = ''
      mkdir -p $out/etc
      echo "" >> $out/etc/motd
      echo 'Welcome to ' | figlet -f term -w 60 -c >> $out/etc/motd
      echo '>>>>> ${lib.toUpper config.networking.hostName} <<<<<' | figlet -f ${pkgs.toilet}/share/figlet/future.tlf -w 60 -c | toilet -f term --gay >> $out/etc/motd
      echo "" >> $out/etc/motd
    '';
  };
in
{
  users.motdFile = "${motd}/etc/motd";
  services.fail2ban.enable = true;
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = lib.mkForce "prohibit-password";
    };
  };

  programs.ssh.hostKeyAlgorithms = [
    "ssh-ed25519"
    # "ssh-rsa"
  ];
}
