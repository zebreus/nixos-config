{ ... }: {
  networking.nftables.enable = true;
  # Firewall is enabled by default, but I am setting it here to be explicit
  networking.firewall.enable = true;
}
