{ pkgs, ... }:
{
  nix = {
    package = pkgs.nixVersions.latest;
    # When free space drops below min-free during a build, nix garbage
    # collects until max-free is available instead of running the disk to 0
    # and failing the build (which took down kashenblade and blanderdash on
    # 2026-08-02).
    settings = {
      min-free = 3 * 1024 * 1024 * 1024;
      max-free = 8 * 1024 * 1024 * 1024;
    };
    extraOptions = ''
      experimental-features = nix-command flakes
      extra-trusted-users = root lennart
      trusted-users = root lennart
    '';
  };
}
