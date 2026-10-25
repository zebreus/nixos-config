# bird-lg looking-glass frontend. Needs global reachability, so it can only be
# assigned to a machine with both static IPs.
import ../../helpers/meta-service.nix "bird-lg" {
  cardinality = "exactlyOne";
  hostFilter = machine: machine.staticIp4 != null && machine.staticIp6 != null;
}
