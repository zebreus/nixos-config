{
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  users.extraGroups.wheel.members = [ "lennart" ];
}
