{
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    ignoreIP = [
      # Do not ban traffic from the antibuilding
      # TODO: Maybe only not ban traffic from workstations?
      "fd10:2030::0/64"
    ];
    bantime = "10m";
    bantime-increment = {
      enable = false;
      maxtime = "48h";
    };
  };
}
