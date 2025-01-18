{ pkgs, lib }:
with pkgs; stdenv.mkDerivation
rec {
  pname = "add-dn42-peer";
  version = "1.0.0";

  src = ./add-dn42-peer.argbash.sh;

  buildInputs = [
    argbash
    makeWrapper
    gnused
    perl
    openssh
    git
    coreutils
    agenix
    wireguard-tools
  ];

  unpackPhase = ":";

  buildPhase = ''
    argbash $src -o ${pname}.sh --type bash-script
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp ${pname}.sh $out/bin/${pname}
    chmod a+x $out/bin/${pname}
    wrapProgram "$out/bin/${pname}" --prefix PATH : ${lib.makeBinPath [gnused perl openssh git wireguard-tools agenix coreutils]}
  '';

  meta.mainProgram = "${pname}";
}

