{ ... }:
{
  security.sudo =
    {
      enable = true;
      wheelNeedsPassword = false;
    };

  users.users.lennart.extraGroups = [ "wheel" ];
}
