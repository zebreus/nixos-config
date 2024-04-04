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
      blanderdash
      sempriaq
      kashenblade
    )
  fi

  function activateConfigurations {
    echo Activating configuration for $host...
    for host in "''${HOSTS[@]}"; do
      nixos-rebuild --flake .#$host --target-host $host switch
    done
  }

  function waitForHosts {
    echo Confirming that all hosts are up...
    for host in "''${HOSTS[@]}"; do
      until nc -vz -w 2 $host 22; do sleep 1; done 
    done
  }

  waitForHosts
  activateConfigurations

  echo Done.
''
