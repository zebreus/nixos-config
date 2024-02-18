let
  # Master recovery key
  # This key is can be used to recover all secrets. Stored offline.
  recovery = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDy99rYCgf4/w8YJ1AGjlOqoLQYdc8vOzwISdaxHech5";

  # Machine keys
  # These keys are only used to decrypt the secrets for the machine.
  # They are present on their machine and have no passphrase
  kashenblade = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIr9j8v8PrnxqxtZuUV9KAK3PGioV70ab3Fax38k8e+L";
  erms = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF+G8YkQ9dQiG85BYIHY4H0D8nn/Ho2m9hSuzD28tRs+";
  kappril = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBgScOMCkR/ILw5uqBUKHyIIO7Id2Io993HbltiuSIR2";

  # User keys
  # Used to login into machines and services
  # These keys are only present on the machines I use interactively and have a passphrase
  lennart = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIBTHzLm8QMhHIo7kFAvtAFnqpspeR3L3gM8kLoG1137";

  # Wireguard public keys
  # Generated with `agenix -d kashenblade_wireguard.age -i ~/.ssh/kashenblade_ed25519 | wg pubkey `
  kashenblade_wireguard = "68AYtSIPLMgVchysyEjjxkA/9iKwvhNExmxd1oIHTxw=";
  erms_wireguard = "u3a0TMHdpaao0OLrZ4wjwMLW2d8nSgZbZkyfhSau/xY=";
  kappril_wireguard = "Rrx4C/a4lDC7Wc+9IPSA/efor1KzDzGRFzqVbi546kI=";
in
{
  # Private machine keys
  # Can be decrypted by recovery key and self
  "kashenblade_ed25519.age".publicKeys = [ recovery kashenblade ];
  "erms_ed25519.age".publicKeys = [ recovery erms ];
  "kappril_ed25519.age".publicKeys = [ recovery kappril ];

  # Private user keys
  # Can be decrypted by recovery key and self
  "lennart_ed25519.age".publicKeys = [ recovery lennart ];

  # Wireguard keys
  # Can be decrypted by recovery key or the respective machine key
  # Generated with `wg genkey | agenix -e kashenblade_wireguard.age`
  "kashenblade_wireguard.age".publicKeys = [ recovery kashenblade ];
  "erms_wireguard.age".publicKeys = [ recovery erms ];
  "kappril_wireguard.age".publicKeys = [ recovery kappril ];
}
