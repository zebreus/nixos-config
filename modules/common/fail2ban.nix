{
  services.fail2ban = {
    enable = true;
    maxretry = 10;
    ignoreIP = [
      # Do not ban traffic from the antibuilding
      # TODO: Maybe only not ban traffic from workstations?
      "fd10:2030::0/64"
      # Always allow from traffic from this local network
      "192.168.2.0/24"
    ];
    bantime = "5m";
    bantime-increment = {
      enable = false;
      maxtime = "48h";
    };
  };
}
