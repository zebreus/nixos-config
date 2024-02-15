# Mixed stuff I probably need on desktop systems
{ ... }:
{
  networking.networkmanager.enable = true;

  users.users.lennart.extraGroups = [ "networkmanager" ];
}
