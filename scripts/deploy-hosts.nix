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

  until nc -vz -w 2 erms 22; do sleep 1; done 
  until nc -vz -w 2 kashenblade 22; do sleep 1; done 
  until nc -vz -w 2 kappril 22; do sleep 1; done 

  echo Making configurations boot default configurations...
  nixos-rebuild --flake .#erms --target-host erms boot
  nixos-rebuild --flake .#kappril --target-host kappril boot
  nixos-rebuild --flake .#kashenblade --target-host kashenblade boot
''
