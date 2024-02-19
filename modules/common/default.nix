{ ... }:
{
  imports = [
    ./boot.nix
    ./cli-programs.nix
    ./git.nix
    ./host_keys.nix
    ./locales.nix
    ./nix.nix
    ./openssh.nix
    ./root.nix
    ./wireguard.nix
    ./zsh.nix
  ];
}
