{ pkgs, ... }:
{
  nix = {
    package = pkgs.nixVersions.latest;
    extraOptions = ''
      experimental-features = nix-command flakes
      extra-trusted-users = root lennart
      trusted-users = root lennart
    '';
  };
}
