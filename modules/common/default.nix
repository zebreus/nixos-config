{ ... }:
{
  imports = [
    ./boot.nix
    ./cli-programs.nix
    ./git.nix
    ./host_keys.nix
    ./locales.nix
    ./nix.nix
    ./zsh.nix
    ./openssh.nix
    ./sudo.nix
    ./lennart.nix
  ];
}
