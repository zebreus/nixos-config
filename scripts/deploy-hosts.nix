{ pkgs, lib }:
with pkgs; writeScriptBin "deploy-hosts" ''
  #!${lib.getExe bash}

  set -x
  set -e

  HOSTS=( $@ )
  if [ -z "$HOSTS" ]; then
    echo "Usage: $0 <host1> <host2> ..."
    echo "If you want to deploy to all hosts, use 'all' as the argument."
    exit 1
  fi

  if [ "$HOSTS" = "all" ]; then
    HOSTS=(
      erms
      kappril
      sempriaq
      kashenblade
    )
  fi

  function buildConfigurations {
    echo Building configuration for $host...
    for host in "''${HOSTS[@]}"; do
      nixos-rebuild --flake .#$host --target-host $host build
    done
  }

  function activateConfigurations {
    echo Activating configuration for $host...
    for host in "''${HOSTS[@]}"; do
      nixos-rebuild --flake .#$host --target-host $host test
    done
  }

  function makeConfigurationsBootDefault {
    echo Making configuration boot default for $host...
    for host in "''${HOSTS[@]}"; do
      nixos-rebuild --flake .#$host --target-host $host boot
    done
  }

  function waitForHosts {
    echo Confirming that all hosts are up...
    for host in "''${HOSTS[@]}"; do
      until nc -vz -w 2 $host 22; do sleep 1; done 
    done
  }

  waitForHosts
  buildConfigurations
  waitForHosts
  activateConfigurations
  waitForHosts
  makeConfigurationsBootDefault

  echo Done.
''
