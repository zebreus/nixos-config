{ ... }:
{
  imports = [
    ./boot.nix
    ./cli-programs.nix
    ./git.nix
    ./host_keys.nix
    ./lennart.nix
    ./locales.nix
    ./nix.nix
    ./openssh.nix
    ./sudo.nix
    ./wireguard.nix
    ./zsh.nix
  ];
}
