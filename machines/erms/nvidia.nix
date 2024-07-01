{ config, ... }:
{
  nixpkgs.config.allowUnfree = true;

  # Hybrid best
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = false;
    nvidiaSettings = true;
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.production;
    powerManagement.enable = true;
    prime = {
      offload.enable = false;
      # Bus ID of the Intel GPU. You can find it using lspci, either under 3D or VGA
      intelBusId = "PCI:0:2:0";
      # Bus ID of the NVIDIA GPU. You can find it using lspci, either under 3D or VGA
      nvidiaBusId = "PCI:1:0:0";
    };
  };
  # programs.xwayland.enable = true;
  # services.xserver.displayManager.gdm.wayland = true;
  hardware.graphics.enable = true;
}
