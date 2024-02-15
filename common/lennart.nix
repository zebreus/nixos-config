{ ... }:
{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.lennart = {
    isNormalUser = true;
    description = "Lennart";
    extraGroups = [ "networkmanager" "wheel" "audio" "docker" "input" "scanner" "libvirtd" ];
  };
}
