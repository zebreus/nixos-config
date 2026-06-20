# AI coding agents
{ lib, config, pkgs, ... }:
{
  config = lib.mkIf config.machines.${config.networking.hostName}.workstation.enable {
    # claude-code ships under an unfree license, so allow just that package
    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [ "claude-code" ];

    environment.systemPackages = with pkgs; [
      claude-code
    ];
  };
}
