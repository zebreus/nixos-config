{ pkgs, lib }:
with pkgs; stdenv.mkDerivation
rec {
  pname = "setup-host";
  version = "1.0.0";

  src = ./setup-host.argbash.sh;

  buildInputs = [
    argbash
    makeWrapper
    gnused
    perl
    openssh
    git
  ];

  unpackPhase = ":";

  buildPhase = ''
    argbash $src -o ${pname}.sh --type bash-script
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp ${pname}.sh $out/bin/${pname}
    chmod a+x $out/bin/${pname}
    wrapProgram "$out/bin/${pname}" --prefix PATH : ${lib.makeBinPath [gnused perl openssh git]}
  '';

  meta.mainProgram = "${pname}";
}

