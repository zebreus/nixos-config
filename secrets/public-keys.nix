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
  # MARKER_PUBLIC_HOST_KEYS

  # User keys
  # Used to login into machines and services
  # These keys are only present on the machines I use interactively and have a passphrase
  lennart = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIBTHzLm8QMhHIo7kFAvtAFnqpspeR3L3gM8kLoG1137";
  lennart_borg_backup_append_only = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEEAbjLP/4tC4+UQCytbISY+ezfEd2NhohU7a33s0XTz";
  lennart_borg_backup_trusted = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAf6WpgqXZg5Nz5/bYaF8fd72zE3TK8FhcCnT+7OGTRr";
  janek_borg_backup_append_only = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBg+saphG0duv0TPObtX9GRQzcz/K6nxHVkuHetMedFp";
  janek_borg_backup_trusted = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBFuAR34VlHKrKSFysyHHvlZgkDobF72Az4iyAIqm1E6";
  janek-proxmox_borg_backup_append_only = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEvD6Xz+LOyq8O9Vls3sOw+Zm1xFA9YGIPjBHsWrRWP/";
  janek-proxmox_borg_backup_trusted = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINtmJswyw0hW65cSYtIJUTWWVlTcFtrIBKAPlvSmL7AT";

  # Wireguard public keys
  # Generated with `nix run .#gen-wireguard-keys`
  erms_wireguard = "RWL8tHmZmfw70WIjx92MVWuSn/rNCz+XlMMuGAV1uAs=";
  kashenblade_wireguard = "LOTNMmJxIFJ6J+QFXX8v0VPGGf5oCfDeYBcLuwi5FQE=";
  kappril_wireguard = "7U4VLHgsJhEyWWiPyRcG6vuqeGd2tjNxScAH0OndCyA=";
  janek_wireguard = "o5Bk0O/x2UI3FS+GAMZhW40ER/o3uBbPeiw0vJPJyiY=";
  janek-proxmox_wireguard = "x/96EtoKnx/Dtgv1+aX61BXvuYYAy89p7T/MbrU7uB8=";
  janek-backup_wireguard = "FQIG2kNEnUEbFfw3oCCstqG3lWjCranGXsfCglriJB8=";
  # MARKER_WIREGUARD_PUBLIC_KEYS

  allMachines = [ erms kashenblade kappril ];
}
