rec {
  # Master recovery key
  # This key is can be used to recover all secrets. Stored offline.
  recovery = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDy99rYCgf4/w8YJ1AGjlOqoLQYdc8vOzwISdaxHech5";

  # Host keys
  # The ed25519 SSH host keys of the machines.
  # They are also used to decrypt the secrets for the machine.
  # They are present on their machine and have no passphrase
  # Generated with `nix run .#gen-host-keys`
  erms = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIjV6XlMFyfQ2MVkvDp45g+yejQ5bMplGBxWs2vSw5tY root@erms";
  kashenblade = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC3mSVmxa5RyNkEeBvKQIsPvyn8bDD+kQHI4pOkHPSvp root@kashenblade";
  kappril = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE80q4TrgnlTN7ZYN/sfr0XI1dH+xHJHRlsrmECJOxMP root@kappril";
  tick = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBFuAR34VlHKrKSFysyHHvlZgkDobF72Az4iyAIqm1E6";
  # MARKER_PUBLIC_HOST_KEYS

  # User keys
  # Used to login into machines and services
  # These keys are only present on the machines I use interactively and have a passphrase
  lennart = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIBTHzLm8QMhHIo7kFAvtAFnqpspeR3L3gM8kLoG1137";
  lennart_borg_backup = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEEAbjLP/4tC4+UQCytbISY+ezfEd2NhohU7a33s0XTz";
  janek_borg_backup_append_only = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBg+saphG0duv0TPObtX9GRQzcz/K6nxHVkuHetMedFp";
  nele_borg_backup_append_only = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEvD6Xz+LOyq8O9Vls3sOw+Zm1xFA9YGIPjBHsWrRWP/";
  simone_borg_backup_append_only = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINtmJswyw0hW65cSYtIJUTWWVlTcFtrIBKAPlvSmL7AT";

  # Wireguard public keys
  # Generated with `nix run .#gen-wireguard-keys`
  erms_wireguard = "RWL8tHmZmfw70WIjx92MVWuSn/rNCz+XlMMuGAV1uAs=";
  kashenblade_wireguard = "LOTNMmJxIFJ6J+QFXX8v0VPGGf5oCfDeYBcLuwi5FQE=";
  kappril_wireguard = "7U4VLHgsJhEyWWiPyRcG6vuqeGd2tjNxScAH0OndCyA=";
  janek_wireguard = "o5Bk0O/x2UI3FS+GAMZhW40ER/o3uBbPeiw0vJPJyiY=";
  nele_wireguard = "x/96EtoKnx/Dtgv1+aX61BXvuYYAy89p7T/MbrU7uB8=";
  simone_wireguard = "1HAWq9gjD+VR6sJv5smN+u20n7lcUzu6FSqzpMXqMzQ=";
  dolt_wireguard = "nO8I7m43IW9EttaKnU1v8HhRhFbFPCeTmmm7jvnM0CI=";
  tick_wireguard = "YF/+vl+fXad/54+2ra7HEeq9TNxwMyCKta8P8YJET0E=";
  # MARKER_WIREGUARD_PUBLIC_KEYS

  allMachines = [ erms kashenblade kappril ];
}
