# Adds piper and enables libratbagd
{ pkgs, ... }:
{
  services.ratbagd.enable = true;
  environment.systemPackages = with pkgs;
    [
      piper
    ];

  users.extraGroups.input.members = [ "lennart" ];
}
