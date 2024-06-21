{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  boot = {
    loader.grub.device = "/dev/vda";
    initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi" ];
    initrd.kernelModules = [ "nvme" ];
  };
  fileSystems."/" = { device = "/dev/vda1"; fsType = "ext4"; };
  swapDevices = [{ device = "/dev/vda2"; }];
  networking.useNetworkd = true;
  # I have to do all these steps to get dns resolution to work
  # TODO: Figure out if networkd can do this for me
  services.resolved.enable = true;
  networking.resolvconf.useLocalResolver = false;
  services.resolved.fallbackDns = [
    "9.9.9.9"
    "1.1.1.1"
  ];
  services.resolved.extraConfig = ''
    DNS=9.9.9.9
    DNSStubListener=no
  '';
}
