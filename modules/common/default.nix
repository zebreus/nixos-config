{ ... }:
{
  imports = [
    ./bird-exporter.nix
    ./boot.nix
    ./cli-programs.nix
    ./dns-resolver.nix
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
