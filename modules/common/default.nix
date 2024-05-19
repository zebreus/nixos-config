{ ... }:
{
  imports = [
    ./boot.nix
    ./cli-programs.nix
    ./fail2ban.nix
    ./git.nix
    ./host_keys.nix
    ./locales.nix
    ./host-email.nix
    ./nix.nix
    ./node-exporter.nix
    ./openssh.nix
    ./root.nix
    ./wireguard.nix
    ./zsh.nix
  ];
}
