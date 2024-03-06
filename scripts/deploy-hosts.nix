{ pkgs, lib }:
with pkgs; writeScriptBin "deploy-hosts" ''
  #!${lib.getExe bash}

  set -x
  set -e

  echo Building configurations...
  nixos-rebuild --flake .#erms --target-host erms build
  nixos-rebuild --flake .#kappril --target-host kappril build
  nixos-rebuild --flake .#kashenblade --target-host kashenblade build

  echo Activating configurations...
  nixos-rebuild --flake .#erms --target-host erms test
  nixos-rebuild --flake .#kappril --target-host kappril test
  nixos-rebuild --flake .#kashenblade --target-host kashenblade test

  echo Making configurations boot default configurations...
  nixos-rebuild --flake .#erms --target-host erms boot
  nixos-rebuild --flake .#kappril --target-host kappril boot
  nixos-rebuild --flake .#kashenblade --target-host kashenblade boot
''
