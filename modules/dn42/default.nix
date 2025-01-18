# Establishes wireguard tunnels with all nodes with static IPs as hubs.
{ config, lib, pkgs, ... }:
let
  machines = lib.attrValues config.machines;
  isRouter = machine: machine.kioubitDn42.enable || machine.routedbitsDn42.enable || machine.pogopeering.enable || machine.sebastiansDn42.enable || machine.adhdDn42.enable || machine.larede01Dn42.enable;
  routers = builtins.filter isRouter machines;

  otherMachines = builtins.filter (machine: machine.name != config.networking.hostName) machines;
  otherRouters = builtins.filter (machine: machine.name != config.networking.hostName) routers;
  isServer = machine: ((machine.staticIp4 != null) || (machine.staticIp6 != null));
  connectedMachines = builtins.filter (otherMachine: (isServer thisMachine) || (isServer otherMachine)) otherMachines;


  thisMachine = config.machines.${config.networking.hostName};
  peeringEnabled = isRouter thisMachine;
  inherit (config.antibuilding) ipv6Prefix;

  script = pkgs.writeShellScriptBin "update-roa" ''
    mkdir -p /etc/bird/
    ${pkgs.curl}/bin/curl -sfSLR {-o,-z}/etc/bird/roa_dn42_v6.conf https://dn42.burble.com/roa/dn42_roa_bird2_6.conf
    ${pkgs.curl}/bin/curl -sfSLR {-o,-z}/etc/bird/roa_dn42.conf https://dn42.burble.com/roa/dn42_roa_bird2_4.conf
    ${pkgs.bird2}/bin/birdc c 
    ${pkgs.bird2}/bin/birdc reload in all
  '';

  networks = lib.imap
    (index: otherMachine: {
      # General information about the network
      name = "antibuilding${builtins.toString otherMachine.address}";
      id = index;
      otherMachine = otherMachine;
    })
    connectedMachines;
in
{
  imports = [
    ./kioubit_de2.nix
    ./pogopeering.nix
    ./larede01_dn42.nix
    ./routedbits_de1.nix
    ./sebastians_dn42.nix
    ./adhd_dn42.nix
    ./echonet_dn42.nix
  ];

  config = lib.mkIf peeringEnabled {
    networking = {
      firewall.interfaces = lib.mkMerge (builtins.map (network: { ${network.name}.allowedTCPPorts = [ 12411 ]; }) networks);
    };

    systemd = {
      timers.dn42-roa = {
        description = "Trigger a ROA table update";

        timerConfig = {
          OnBootSec = "5m";
          OnUnitInactiveSec = "1h";
          Unit = "dn42-roa.service";
        };

        wantedBy = [ "timers.target" ];
        before = [ "bird.service" ];
      };

      services = {
        dn42-roa = {
          after = [ "network.target" ];
          description = "DN42 ROA Updated";
          unitConfig = {
            Type = "one-shot";
          };
          serviceConfig = {
            ExecStart = "${script}/bin/update-roa";
          };
        };
      };
    };

    services.bird2 = {
      enable = true;
      autoReload = true;
      preCheckConfig = lib.mkOrder 2 ''
        # Remove roa files for checking, because they are only available at runtime
        sed -i 's|include "/etc/bird/roa_dn42.conf";||' bird2.conf
        sed -i 's|include "/etc/bird/roa_dn42_v6.conf";||' bird2.conf

        cat -n bird2.conf
      '';
      config = ''
        define OWNAS = 4242421403;
        define OWNNET = 172.20.179.128/27;
        define OWNNETv6 = ${ipv6Prefix}::/48;
        define OWNNETSET = [ 172.20.179.128/27 ];
        define OWNNETSETv6 = [ ${ipv6Prefix}::/48 ];

        ipv4 table bgp4;
        ipv6 table bgp6;

        function is_self_net() {
          return net ~ OWNNETSET;
        }

        function is_self_net_v6() {
          return net ~ OWNNETSETv6;
        }

        function is_valid_network() {
          return net ~ [
            172.20.0.0/14{21,29}, # dn42
            172.20.0.0/24{28,32}, # dn42 Anycast
            172.21.0.0/24{28,32}, # dn42 Anycast
            172.22.0.0/24{28,32}, # dn42 Anycast
            172.23.0.0/24{28,32}, # dn42 Anycast
            172.31.0.0/16+,       # ChaosVPN
            10.100.0.0/14+,       # ChaosVPN
            10.127.0.0/16{16,32}, # neonetwork
            10.0.0.0/8{15,24}     # Freifunk.net
          ];
        }

        function is_valid_network_v6() {
          return net ~ [
            fd00::/8{44,64} # ULA address space as per RFC 4193
          ];
        }

        roa4 table dn42_roa;
        roa6 table dn42_roa_v6;

        protocol static {
            roa4 { table dn42_roa; };
            include "/etc/bird/roa_dn42.conf";
        };

        protocol static {
            roa6 { table dn42_roa_v6; };
            include "/etc/bird/roa_dn42_v6.conf";
        };

        protocol static {
            route OWNNET unreachable;

            ipv4 {
                import all;
                export none;
            };
        }

        protocol static {
            route OWNNETv6 unreachable;

            ipv6 {
                import all;
                export none;
            };
        }

        protocol pipe bgp6_to_master6 {
                table bgp6;
                peer table master6;
                export filter {
                        print "THIS got route to ", net , " from ", from , " with gateway ", gw, " on ", ifname;
                        if source !~ [RTS_BGP] then {
                          reject;
                        }
                        # Crude test if we are using EBGP or BGP.
                        # I think routes are aggregated before, so this should only match if we have a direct connection to the shortest AS path
                        if ifname = "antibuilding" ${lib.concatMapStrings (machine: ''|| ifname = "antibuilding${builtins.toString machine.address}" '') machines} then {
                          print "Rejecting ", net , ", because it is not a direct connection. We will import this route into the master table via babel";
                          reject;
                        }
                        # # TODO: Maybe this can replace the previous statement
                        # if from !~ [ ${ipv6Prefix}::/48{48,128} ] then {
                        #   reject;
                        # }

                        # We have a direct connection with (I think) the lowest number of hops
                        accept;
                };
                import filter {
                        # Import routes to other devices in our network to the BGP table, because bird2 fails to resolve the nexthop on received routes otherwise
                        if source !~ [RTS_BABEL, RTS_STATIC] then {
                          reject;
                        }
                        if net !~ [ ${ipv6Prefix}::/48{48,128} ] then {
                          reject;
                        }
                        # Lowest preference
                        preference = 0;
                        accept;
                };
        }
        protocol pipe bgp4_to_master4 {
                table bgp4;
                peer table master4;
                export filter {
                        print "THIS got route to ", net , " from ", from , " with gateway ", gw, " on ", ifname;
                        if source !~ [RTS_BGP] then {
                          reject;
                        }
                        # Crude test if we are using EBGP or BGP.
                        # I think routes are aggregated before, so this should only match if we have a direct connection to the shortest AS path
                        if ifname = "antibuilding" ${lib.concatMapStrings (machine: ''|| ifname = "antibuilding${builtins.toString machine.address}" '') machines} then {
                          print "Rejecting ", net , ", because it is not a direct connection. We will import this route into the master table via babel";
                          reject;
                        }
                        # TODO: Maybe this can replace the previous statement
                        # if from !~ [ ${ipv6Prefix}::/48{48,128} ] then {
                        #   reject;
                        # }
                        
                        # We have a direct connection with (I think) the lowest number of hops
                        accept;
                };
                import filter {
                        # Import routes to other devices in our network to the BGP table, because bird2 fails to resolve the nexthop on received routes otherwise
                        if source !~ [RTS_BABEL, RTS_STATIC] then {
                          reject;
                        }
                        if net !~ [ 172.20.179.128/27{27,32} ] then {
                          reject;
                        }
                        # Lowest preference
                        preference = 0;
                        accept;
                };
        }

        template bgp dnpeers {
            local as OWNAS;
            path metric 1;
            
            enable extended messages on;
            graceful restart on;
            long lived graceful restart on;
          
            ipv4 {
                table bgp4;
                extended next hop on;
                next hop self on;
                import filter {
                  if !is_valid_network() then {
                    print "[dn42v4] Not importing ", net, " because it is not a valid IPv6 network", bgp_path;
                    reject;
                  }
                  if is_self_net() then {
                    print "[dn42v4] Not importing ", net, " because it is selfnet ", bgp_path;
                    reject;
                  }
                  if (roa_check(dn42_roa, net, bgp_path.last) != ROA_VALID) then {
                    print "[dn42v4] Not importing ", net, " because the ROA check failed for ASN ", bgp_path.last, " Full ASN path: ", bgp_path;
                    reject;
                  }
                  
                  print "[dn42v4] Importing ", net, " AS PATH: ", bgp_path;
                  accept;
                };
                export filter {
                  if !is_valid_network() then {
                    print "[dn42v4] Not exporting ", net, " because it isnt a valid network";
                    reject;
                  }
                  if source !~ [RTS_STATIC, RTS_BGP] then {
                    print "[dn42v4] Not exporting ", net, " because it is not static or BGP, but ", source;
                    reject;
                  }

                  print "[dn42v4] Exporting ", net, " via ", bgp_path;
                  accept;
                };
                import limit 9000 action block;
            };
          
            ipv6 {
                table bgp6;
                extended next hop on;
                next hop self on;
                import filter {
                  if !is_valid_network_v6() then {
                    print "[dn42] Not importing ", net, " because it is not a valid IPv6 network", bgp_path;
                    reject;
                  }
                  if is_self_net_v6() then {
                    print "[dn42] Not importing ", net, " because it is selfnet ", bgp_path;
                    reject;
                  }

                  if (roa_check(dn42_roa_v6, net, bgp_path.last) != ROA_VALID) then {
                    print "[dn42] Not importing ", net, " because the ROA check failed for ASN ", bgp_path.last, " Full ASN path: ", bgp_path;
                    reject;
                  }

                  print "[dn42] Importing ", net, " AS PATH: ", bgp_path;
                  accept;
                };
                export filter {
                  if !is_valid_network_v6() then {
                    print "[dn42] Not exporting ", net, " because it isnt a valid network";
                    reject;
                  }
                  if source !~ [RTS_STATIC, RTS_BGP] then {
                    print "[dn42] Not exporting ", net, " because it is not static or BGP, but ", source;
                    reject;
                  }

                  print "[dn42] Exporting ", net, " via ", bgp_path;
                  accept;
                };
                import limit 9000 action block; 
            };
        }

        template bgp ibgp_router {
            local as OWNAS;

            enable extended messages on;
            graceful restart on;
            long lived graceful restart on;
        
            ipv4 {
                table bgp4;
                extended next hop on;
                import filter {
                  if source != RTS_BGP then {
                    print "[ibgpv4] Not importing ", net, " because it is not RTS_BGP, but ", source; 
                    reject; 
                  }
                  if !is_valid_network() then {
                    print "[ibgpv4] Not importing ", net, " because it is not a valid network"; 
                    reject; 
                  }
                  if is_self_net() then {
                    print "[ibgpv4] Not importing ", net, " because it is selfnet";
                    reject; 
                  }
                  print "[ibgpv4] Importing ", net, " with source ", source;
                  accept;
                };
                export where source = RTS_BGP && is_valid_network() && !is_self_net();
                next hop self;
            };
        
            ipv6 {
                debug all;
                table bgp6;
                extended next hop on;
                import filter {
                  if source != RTS_BGP then {
                    print "[ibgp] Not importing ", net, " because it is not RTS_BGP, but ", source; 
                    reject; 
                  }
                  if !is_valid_network_v6() then {
                    print "[ibgp] Not importing ", net, " because it is not a valid network"; 
                    reject; 
                  }
                  if is_self_net_v6() then {
                    print "[ibgp] Not importing ", net, " because it is selfnet";
                    reject; 
                  }
                  print "[ibgp] Importing ", net, " with source ", source;
                  accept;
                };
                export where source = RTS_BGP && is_valid_network_v6() && !is_self_net_v6();
                next hop self;
            };
        }
      '' + (lib.concatMapStrings
        (router: ''
          protocol bgp ibgp_${router.name} from ibgp_router {
              neighbor ${ipv6Prefix}::${builtins.toString router.address} as OWNAS;
          }
        '')
        otherRouters);
    };
  };
}
