# Names shared by the files of this module.
{ lib }:
rec {
  unit = name: "isolated-container-${name}";
  networkUnit = name: "${unit name}-network";
  user = name: "isolated-${name}";
  runtimeDir = name: "/run/isolated-containers/${name}";
  # The network unit's runtime directory (relative to /run), with a symlink to
  # the container's network namespace in it.
  networkDir = name: "isolated-containers/${name}-network";
  netns = name: "/run/${networkDir name}/netns";

  # The systemd.services entries of the containers' units.
  units = cfg: f: lib.mapAttrs' (name: container: lib.nameValuePair (unit name) (f name container)) cfg;
}
