# Shared packaging for the *arr family: fetch the upstream prebuilt .NET
# bundle for the pinned version and make it run against nixpkgs glibc.
{ pkgs, lib }:
{
  pname,
  binary,
  version,
  branch,
  src,
  extraLibs ? [ ],
  removeFiles ? [ ],
}:
let
  runtimeLibs =
    with pkgs;
    [
      stdenv.cc.cc.lib
      icu
      openssl
      sqlite
      zlib
    ]
    ++ extraLibs;
in
pkgs.stdenv.mkDerivation {
  inherit pname version src;

  nativeBuildInputs = with pkgs; [
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = runtimeLibs;
  autoPatchelfIgnoreMissingDeps = [ "liblttng-ust.so.0" ];
  dontStrip = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/${pname}/bin $out/bin
    cp -r . $out/lib/${pname}/bin
    rm -rf $out/lib/${pname}/bin/${binary}.Update ${
      lib.concatMapStringsSep " " (f: "$out/lib/${pname}/bin/${f}") removeFiles
    }
    printf "UpdateMethod=docker\nBranch=%s\nPackageVersion=%s\nPackageAuthor=[nklmilojevic](https://github.com/nklmilojevic)\n" \
      "${branch}" "${version}" > $out/lib/${pname}/package_info
    makeWrapper $out/lib/${pname}/bin/${binary} $out/bin/${binary} \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibs}
    runHook postInstall
  '';
}
