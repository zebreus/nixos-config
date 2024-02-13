{ config, ... }:
{
  nixpkgs.config.allowUnfree = true;

  # Hybrid best
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = false;
  hardware.nvidia.nvidiaSettings = true;
  hardware.nvidia.modesetting.enable = true;
  # programs.xwayland.enable = true;
  # services.xserver.displayManager.gdm.wayland = true;
  hardware.opengl.enable = true;
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.production;
  hardware.nvidia.powerManagement.enable = true;
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  hardware.nvidia.prime = {
    offload.enable = false;
    # Bus ID of the Intel GPU. You can find it using lspci, either under 3D or VGA
    intelBusId = "PCI:0:2:0";
    # Bus ID of the NVIDIA GPU. You can find it using lspci, either under 3D or VGA
    nvidiaBusId = "PCI:1:0:0";
  };
}
