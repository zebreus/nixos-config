# nixpkgs' gVisor, updated to release-20261019.0. Releases since 2026-09-15
# report STATX_ATTR_MOUNT_ROOT, which systemd needs to boot as PID 1 (see the
# assertion in ./default.nix). Drop this once nixpkgs has such a release, if it
# also builds the sidecar binaries in bin/gvisor-bin/ that newer runsc needs.
{ gvisor, buildGo127Module, fetchFromGitHub }:
(gvisor.override { buildGoModule = buildGo127Module; }).overrideAttrs (old: rec {
  version = "20261019.0";
  # The "Merge release-20261019.0 (automated)" commit on the go branch.
  src = fetchFromGitHub {
    owner = "google";
    repo = "gvisor";
    rev = "02a34e56a43873ddd1ff5efdda37f63af1b6e7cc";
    hash = "sha256-UNQjk9tJAbyxmf/RFNlIJmhjVT9tEI8uv7/GFVkATKA=";
  };
  vendorHash = "sha256-by7tg6USNBfomQuPVqeDaRPDfWJcVLVz7K/BijoyZpA=";
  # nixpkgs' go.mod fix is upstream by now.
  patches = [ ];

  subPackages = old.subPackages ++ [ "runsc/cmd/sentry" ];
  # runsc and its sidecars check that they come from the same release.
  ldflags = old.ldflags ++ [ "-X gvisor.dev/gvisor/runsc/version.version=release-${version}" ];

  # The C sidecars are freestanding static binaries, built with upstream's flags.
  hardeningDisable = [ "all" ];
  postInstall = old.postInstall + ''
    mkdir -p $out/bin/gvisor-bin
    mv $out/bin/sentry $out/bin/gvisor-bin/gvisor_sentry
    for sidecar in prewarmer:gvisor-sentry-prewarmer procumounter:gvisor-proc-umounter fdparking:runsc-fd-parking; do
      $CC -Os -fno-pie -no-pie -ffreestanding -fno-sanitize=all -fno-stack-protector \
        -fno-asynchronous-unwind-tables -fno-unwind-tables -static -nostdlib -nostartfiles \
        -Wl,--build-id=none -Wl,--gc-sections -Wl,-s -Wl,-n \
        -o $out/bin/gvisor-bin/''${sidecar#*:} runsc/''${sidecar%:*}/''${sidecar%:*}.c
    done
  '';
})
