{ lib, pkgs, ... }:
let
  domain_name = "ubuntu-vm";
  domain_uuid = "e5b5d6fa-153b-4289-be2c-f48db7887f1e";
  memory = { count = 8; unit = "GiB"; };
  vcpu = { count = 4; };
  net_iface_mac = "00:06:46:21:49:d5";
  net_bridge_name = "ubuntubridge";
  net_name = "ubuntunet";
  net_uuid = "8d111de1-ac1d-4a9f-82d4-7c8281d1db96";
  pool_name = "ubuntupool";
  pool_uuid = "94afeae2-fe98-4269-b501-bae828b062ce";
  pool_path = "/mnt/ubuntuvm";
  volume_name = "ubuntu.qcow2";
  net_subnet = "192.168.135";
in
{
  config = {
    virtualisation.libvirt = {
      enable = true;
      swtpm.enable = true;
      connections."qemu:///system" = {
        domains = [
          {
            active = true;
            restart = true;

            definition =
              let
                base_image = builtins.fetchurl {
                  url = "https://cloud-images.ubuntu.com/releases/noble/release-20260225/ubuntu-24.04-server-cloudimg-amd64.img";
                  sha256 = "sha256:08cv2sznq6ifvalpsaqv45qph66ifcdd6f5i8ms5r9d3x3sxk9ks";
                };
                meta_data = pkgs.writeText "meta-data" ''
                  instance_id: ${domain_name}
                  hostname: ${domain_name}
                  local-hostname: ${domain_name}
                '';
                user_data = pkgs.writeText "user-data" ''
                  #cloud-config
                  package_reboot_if_required: true
                  package_update: true
                  package_upgrade: true
                  packages:
                   - btop
                   - curl
                   - dash
                   - findutils
                   - fish
                   - git
                   - hdparm
                   - htop
                   - jq
                   - nano
                   - nmap
                   - rsync
                   - sysstat
                   - tmux
                   - xz-utils

                  mounts:
                   - [ autotier, /mnt/autotier, virtiofs, "defaults" ]

                  users: []
                  ssh_authorized_keys:
                   - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIBTHzLm8QMhHIo7kFAvtAFnqpspeR3L3gM8kLoG1137 lennart@erms
                  ssh_pwauth: false
                  disable_root: false
                  ssh_publish_hostkeys:
                    blacklist: [rsa]
                    enabled: true
                  ssh_quiet_keygen: true
                '';
                config_image = pkgs.runCommand "cidata.iso" { } ''
                  ${pkgs.cdrkit}/bin/genisoimage -output $out -V cidata -r -J -graft-points user-data=${user_data} meta-data=${meta_data}
                '';
              in
              lib.domain.writeXML {
                type = "kvm";
                inherit vcpu memory;
                uuid = domain_uuid;
                name = domain_name;

                os = {
                  type = "hvm";
                  arch = "x86_64";
                  machine = "q35";
                  boot = [{ dev = "hd"; }];
                };
                features = {
                  acpi = { };
                  apic = { };
                };
                cpu = { mode = "host-passthrough"; };
                clock = {
                  offset = "utc";
                  timer = [
                    { name = "rtc"; tickpolicy = "catchup"; }
                    { name = "pit"; tickpolicy = "delay"; }
                    { name = "hpet"; present = false; }
                  ];
                };
                memoryBacking = {
                  source = { type = "memfd"; };
                  access = { mode = "shared"; };
                };
                devices = {
                  emulator = "${pkgs.qemu}/bin/qemu-system-x86_64";
                  disk = [
                    {
                      type = "volume";
                      device = "disk";
                      driver =
                        {
                          name = "qemu";
                          type = "qcow2";
                          cache = "none";
                          discard = "unmap";
                        };
                      source = { pool = pool_name; volume = volume_name; };
                      backingStore = {
                        type = "file";
                        format = { type = "qcow2"; };
                        source = { file = base_image; };
                        readonly = true;
                      };
                      target = { dev = "vda"; bus = "virtio"; };
                    }
                    {
                      type = "file";
                      device = "cdrom";
                      driver =
                        {
                          name = "qemu";
                          type = "raw";
                        };
                      source = { file = "${config_image}"; };

                      target = { dev = "sdc"; bus = "sata"; };
                      readonly = true;
                    }
                  ];
                  filesystem = {
                    type = "mount";
                    accessmode = "passthrough";
                    driver = {
                      type = "virtiofs";
                      queue = "1024";
                    };
                    source = { dir = "/mnt/autotier"; };
                    target = { dir = "autotier"; };
                    binary = {
                      path = "${pkgs.virtiofsd}/bin/virtiofsd";
                      xattr = true;
                      cache = { mode = "always"; };
                      lock = { posix = true; flock = true; };
                    };
                  };
                  #           
                  interface = {
                    type = "bridge";
                    model = { type = "virtio"; };
                    mac = { address = net_iface_mac; };
                    source = { bridge = net_bridge_name; };
                  };
                  channel = [{
                    type = "unix";
                    target = { type = "virtio"; name = "org.qemu.guest_agent.0"; };
                  }];
                  sound = { model = "ich9"; };
                  rng = {
                    model = "virtio";
                    backend = { model = "random"; source = "/dev/random"; };
                  };
                  serial = {
                    type = "pty";
                    target = {
                      type = "isa-serial";
                      port = 0;
                      model = { name = "isa-serial"; };
                    };
                  };
                  console = {
                    type = "pty";
                    target = { type = "serial"; port = 0; };
                  };
                };
              };
          }
        ];
        networks = [
          {
            definition = lib.network.writeXML (
              {
                name = net_name;
                uuid = net_uuid;
                forward = {
                  mode = "nat";
                  nat = { };
                };
                bridge = { name = net_bridge_name; };
                ip = {
                  address = "${net_subnet}.1";
                  netmask = "255.255.255.0";
                  dhcp = {
                    range = {
                      start = "${net_subnet}.2";
                      end = "${net_subnet}.2";
                    };
                  };
                };
                dns = {
                  enable = false;
                };
                "xmlns:dnsmasq" = "http://libvirt.org/schemas/network/dnsmasq/1.0";
                "dnsmasq:options" = {
                  "dnsmasq:option" = [
                    { value = "dhcp-option=6,9.9.9.10,149.112.112.10"; }
                  ];
                };
              }
            );
            active = true;
          }
        ];
        pools = [
          {
            definition = lib.pool.writeXML {
              name = pool_name;
              uuid = pool_uuid;
              type = "dir";

              target = { path = pool_path; };
            };
            active = true;
            restart = true;
            volumes = [
              {
                present = true;
                definition = lib.volume.writeXML {
                  # TODO: Mention volume name only once
                  name = volume_name;
                  capacity = { count = 100; unit = "GB"; };
                  target = { path = "${pool_path}/${volume_name}"; format = { type = "qcow2"; }; };
                };
                name = volume_name;
              }
            ];
          }
        ];
      };
    };

    networking.firewall.interfaces."${net_bridge_name}" = {
      allowedUDPPorts = [ 67 68 ];
    };

  };
  imports = [
    ({ lib, pkgs, config, ... }: {
      # libvirt light
      virtualisation.libvirtd = {
        enable = true;
        qemu = {
          runAsRoot = false;
          swtpm.enable = true;
        };
      };

      environment.systemPackages = with pkgs; [
        qemu
        virtiofsd
        libvirt # For virsh
      ];

      users.extraGroups.libvirtd.members = [ "lennart" ];
    })
  ];
}
