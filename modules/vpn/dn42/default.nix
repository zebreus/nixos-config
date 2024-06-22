# Establishes wireguard tunnels with all nodes with static IPs as hubs.
{ config, lib, pkgs, ... }:
let
  cfg = config.machines.${config.networking.hostName}.routedbitsDn42;
  inherit (config.antibuilding) ipv6Prefix;

  script = pkgs.writeShellScriptBin "update-roa" ''
    mkdir -p /etc/bird/
    ${pkgs.curl}/bin/curl -sfSLR {-o,-z}/etc/bird/roa_dn42_v6.conf https://dn42.burble.com/roa/dn42_roa_bird2_6.conf
    ${pkgs.curl}/bin/curl -sfSLR {-o,-z}/etc/bird/roa_dn42.conf https://dn42.burble.com/roa/dn42_roa_bird2_4.conf
    ${pkgs.bird2}/bin/birdc c 
    ${pkgs.bird2}/bin/birdc reload in all
  '';
in
{
  imports = [
    ./kioubit_de1.nix
    ./routedbits_de1.nix
  ];

  config = lib.mkIf cfg.enable {
    # Enable IP forwarding
    boot = {
      kernel.sysctl."net.ipv6.conf.all.forwarding" = lib.mkDefault true;
      kernel.sysctl."net.ipv4.ip_forward" = lib.mkDefault true;
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
        ################################################
        #               Variable header                #
        ################################################

        define OWNAS =  4242421403;
        define OWNNET = 172.20.179.128/27;
        define OWNNETv6 = ${ipv6Prefix}::/48;
        define OWNNETSET = [ 172.20.179.128/27 ];
        define OWNNETSETv6 = [ ${ipv6Prefix}::/48 ];

        ################################################
        #                 Header end                   #
        ################################################

        # router id OWNIP;

        # protocol device {
        #     scan time 10;
        # }

        /*
         *  Utility functions
         */

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

        function is_valid_network_v6() {
          return net ~ [
            fd00::/8{44,64} # ULA address space as per RFC 4193
          ];
        }

        ipv4 table routedbits_master4;
        ipv6 table routedbits_master6;



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

        template bgp dnpeers {
            local as OWNAS;
            path metric 1;
            
            enable extended messages on;
            graceful restart on;
            long lived graceful restart on;
          
            ipv4 {
                extended next hop on;
                next hop self on;
                import filter {
                  if is_valid_network() && !is_self_net() then {
                    if (roa_check(dn42_roa, net, bgp_path.last) != ROA_VALID) then {
                      # Reject when unknown or invalid according to ROA
                      print "[dn42] ROA check failed for ", net, " ASN ", bgp_path.last;
                      reject;
                    } else accept;
                  } else reject;
                };
          
                export filter { if is_valid_network() && source ~ [RTS_STATIC, RTS_BGP] then accept; else reject; };
                import limit 9000 action block;
            };
          
            ipv6 {
                extended next hop on;
                next hop self on;
                import filter {
                  if is_valid_network_v6() && !is_self_net_v6() then {
                    if (roa_check(dn42_roa_v6, net, bgp_path.last) != ROA_VALID) then {
                      # Reject when unknown or invalid according to ROA
                      print "[dn42] ROA check failed for ", net, " ASN ", bgp_path.last;
                      reject;
                    } else accept;
                  } else reject;
                };
                export filter { if is_valid_network_v6() && source ~ [RTS_STATIC, RTS_BGP] then accept; else reject; };
                import limit 9000 action block; 
            };
        }

        # template bgp dnpeers {
        #     local as OWNAS;
        #     path metric 1;
        #     # graceful restart off;

        #     # ipv4 {
        #     #     table routedbits_master4;
        #     #     extended next hop on;
        #     #     next hop self on;
        #     #     gateway direct;

        #     #     import filter {
        #     #       if is_valid_network() && !is_self_net() then {
        #     #         if (roa_check(dn42_roa, net, bgp_path.last) != ROA_VALID) then {
        #     #           # Reject when unknown or invalid according to ROA
        #     #           print "[dn42] ROA check failed for ", net, " ASN ", bgp_path.last;
        #     #           reject;
        #     #         } else accept;
        #     #       } else reject;
        #     #     };

        #     #     export filter { if is_valid_network() && source ~ [RTS_STATIC] then accept; else reject; };
        #     #     import limit 9000 action block;
        #     # };

        #     ipv4 {
        #         # extended next hop on;
        #         # require extended next hop on;
        #         next hop self on;
        #         # gateway direct;
        #         # export table on;
                  

        #         import filter {
        #           if !is_self_net() then {
        #             accept;
        #           }
        #               print "[dn42] ROA check failed for ", net, " ASN ", bgp_path.last;
        #               reject;

        #           # if is_valid_network() && !is_self_net() then {
        #           #   if (roa_check(dn42_roa, net, bgp_path.last) != ROA_VALID) then {
        #           #     # Reject when unknown or invalid according to ROA
        #           #     print "[dn42] ROA check failed for ", net, " ASN ", bgp_path.last;
        #           #     reject;
        #           #   } else accept;
        #           # } else reject;
        #         };

        #         export filter { if is_valid_network() && source ~ [RTS_STATIC] then accept; else reject; };
        #         import limit 9000 action block;
        #     };

        #     ipv6 {   
        #         # extended next hop on;
        #         # require extended next hop on;
        #         next hop self on;
        #         # gateway direct;
        #         # export table on;
                  
        #         import filter {
        #             # reject;
                    
        #           if !is_self_net_v6() then {
        #             # if (roa_check(dn42_roa_v6, net, bgp_path.last) != ROA_VALID) then {
        #             #   # Reject when unknown or invalid according to ROA
        #             #   print "[dn42] ROA check failed for ", net, " ASN ", bgp_path.last;
        #             #   reject;
        #             # } else {
        #               print "[dn42] Accept import of ", net, " ASN ", bgp_path.last;
        #               accept;
        #             # }
        #           } else {
        #             print "that path";
        #             reject;
        #           }
        #         };
        #         export filter { if source ~ [RTS_STATIC] then {
        #           print "[dn42] Exporting ", net, " ASN ", bgp_path.last;
        #           accept;
        #         } else reject; };
        #         import limit 9000 action block; 
        #     };
        # }
      '';
    };
  };
}
