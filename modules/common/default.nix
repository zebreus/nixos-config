{ ... }:
{
  imports = [
    ./boot.nix
    ./cli-programs.nix
    ./fail2ban.nix
    ./firewall.nix
    ./git.nix
    ./host_keys.nix
    ./locales.nix
    ./host-email.nix
    ./nix.nix
    ./node-exporter.nix
    ./openssh.nix
    ./root.nix
    ./tmp.nix
    ./zsh.nix
  ];
}
