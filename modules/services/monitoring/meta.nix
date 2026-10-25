# Run grafana and the prometheus collector. Needs global reachability, so it can
# only be assigned to a machine with both static IPs.
import ../../helpers/meta-service.nix "monitoring" {
  cardinality = "exactlyOne";
  hostFilter = machine: machine.staticIp4 != null && machine.staticIp6 != null;
}
