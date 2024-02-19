{
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    ignoreIP = [
      # Do not ban traffic from the antibuilding
      # TODO: Maybe only not ban traffic from workstations?
      "10.20.30.0/24"
    ];
    bantime = "10m";
    bantime-increment = {
      enable = false;
      maxtime = "48h";
    };
  };
}
