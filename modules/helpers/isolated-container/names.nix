# Names and addresses shared by the files of this module.
{ lib }:
rec {
  unit = name: "isolated-container-${name}";
  runtimeDir = name: "/run/isolated-containers/${name}";
  interface = name: "ic-${name}";

  # 10.231.<n>.0/30 for the n-th container by name: .1 is the host, .2 the container.
  subnet = cfg: name: "10.231.${toString (lib.lists.findFirstIndex (n: n == name) null (builtins.attrNames cfg))}";

  # The systemd.services entries of the containers' units.
  units = cfg: f: lib.mapAttrs' (name: container: lib.nameValuePair (unit name) (f name container)) cfg;
}
