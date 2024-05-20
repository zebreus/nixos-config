# Workstations should be able to build for all architectures I have machines for
{ lib, config, ... }: {
  config = lib.mkIf config.machines.${config.networking.hostName}.workstation.enable {
    boot.binfmt.emulatedSystems = builtins.filter (system: system != config.nixpkgs.system) [ "aarch64-linux" "x86_64-linux" ];
  };
}
