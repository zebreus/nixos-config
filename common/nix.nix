{ pkgs, ... }:
{
  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    # extraOptions = ''
    #   extra-trusted-users = lennart
    #   trusted-users = root lennart
    # '';
  };
}
