let
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

  # Wireguard public keys
  # Generated with `nix run .#gen-wireguard-keys`
  erms_wireguard = "RWL8tHmZmfw70WIjx92MVWuSn/rNCz+XlMMuGAV1uAs=";
  kashenblade_wireguard = "LOTNMmJxIFJ6J+QFXX8v0VPGGf5oCfDeYBcLuwi5FQE=";
  kappril_wireguard = "7U4VLHgsJhEyWWiPyRcG6vuqeGd2tjNxScAH0OndCyA=";
  # MARKER_WIREGUARD_PUBLIC_KEYS
in
{
  # SSH host keys
  # The ed25519 keys are also used for agenix
  # 
  # Can be decrypted by recovery key and self
  # Storing the public keys in here is redundant, but it makes it easier to deploy them
  #
  # Generated with `nix run .#gen-host-keys`
  "erms_ed25519.age".publicKeys = [ recovery erms ];
  "erms_ed25519_pub.age".publicKeys = [ recovery erms ];
  "erms_rsa.age".publicKeys = [ recovery erms ];
  "erms_rsa_pub.age".publicKeys = [ recovery erms ];
  "kashenblade_ed25519.age".publicKeys = [ recovery kashenblade ];
  "kashenblade_ed25519_pub.age".publicKeys = [ recovery kashenblade ];
  "kashenblade_rsa.age".publicKeys = [ recovery kashenblade ];
  "kashenblade_rsa_pub.age".publicKeys = [ recovery kashenblade ];
  "kappril_ed25519.age".publicKeys = [ recovery kappril ];
  "kappril_ed25519_pub.age".publicKeys = [ recovery kappril ];
  "kappril_rsa.age".publicKeys = [ recovery kappril ];
  "kappril_rsa_pub.age".publicKeys = [ recovery kappril ];
  # MARKER_HOST_KEYS

  # Private user keys
  # Can be decrypted by recovery key and self
  "lennart_ed25519.age".publicKeys = [ recovery lennart ];
  "lennart_ed25519_pub.age".publicKeys = [ recovery lennart ];

  # Wireguard keys
  # Can be decrypted by recovery key or the respective machine key
  # Generated with `nix run .#gen-wireguard-keys`
  "erms_wireguard.age".publicKeys = [ recovery erms ];
  "erms_wireguard_psk.age".publicKeys = [ recovery erms ];
  "erms_wireguard_pub.age".publicKeys = [ recovery erms ];
  "kashenblade_wireguard.age".publicKeys = [ recovery kashenblade ];
  "kashenblade_wireguard_psk.age".publicKeys = [ recovery kashenblade ];
  "kashenblade_wireguard_pub.age".publicKeys = [ recovery kashenblade ];
  "kappril_wireguard.age".publicKeys = [ recovery kappril ];
  "kappril_wireguard_psk.age".publicKeys = [ recovery kappril ];
  "kappril_wireguard_pub.age".publicKeys = [ recovery kappril ];
  # MARKER_WIREGUARD_KEYS

  # Shared secret for coturn.
  # Matrix does not support a file option, but can load extra config files, so we use a config file that only sets the secret
  "coturn_static_auth_secret.age".publicKeys = [ recovery kashenblade ];
  "coturn_static_auth_secret_matrix_config.age".publicKeys = [ recovery kashenblade ];
}
