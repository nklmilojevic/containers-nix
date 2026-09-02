{
  pkgs,
  lib,
  name,
  helpers,
}:
let
  inherit (helpers) fetchSource mkImage rootFile;
  branch = "develop";
  updateUrl =
    arch:
    "https://radarr.servarr.com/v1/update/${branch}/updatefile?version=${version}&os=linux&runtime=netcore&arch=${arch}";
  hashes = helpers.readHashes ./.;

  # renovate: datasource=custom.servarr-develop depName=radarr versioning=loose
  version = "6.4.3.10645";
  source = "https://github.com/Radarr/Radarr";
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  sources = {
    radarr.name = "Radarr.${branch}.${version}.linux-core.tar.gz";
    radarr.urls = {
      x86_64-linux = updateUrl "x64";
      aarch64-linux = updateUrl "arm64";
    };
  };

  package = pkgs.stdenv.mkDerivation {
    pname = name;
    inherit version;
    src = fetchSource sources hashes "radarr";

    nativeBuildInputs = with pkgs; [
      autoPatchelfHook
      makeWrapper
    ];
    buildInputs = with pkgs; [
      stdenv.cc.cc.lib
      icu
      openssl
      sqlite
      zlib
    ];
    autoPatchelfIgnoreMissingDeps = [ "liblttng-ust.so.0" ];
    dontStrip = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/radarr/bin $out/bin
      cp -r . $out/lib/radarr/bin
      rm -rf $out/lib/radarr/bin/Radarr.Update
      printf "UpdateMethod=docker\nBranch=%s\nPackageVersion=%s\nPackageAuthor=[nklmilojevic](https://github.com/nklmilojevic)\n" \
        "${branch}" "${version}" > $out/lib/radarr/package_info
      makeWrapper $out/lib/radarr/bin/Radarr $out/bin/Radarr \
        --prefix LD_LIBRARY_PATH : ${
          lib.makeLibraryPath (
            with pkgs;
            [
              stdenv.cc.cc.lib
              icu
              openssl
              sqlite
              zlib
            ]
          )
        }
      runHook postInstall
    '';
  };

  image = mkImage {
    inherit name version source;
    contents = [
      package
      (rootFile "/entrypoint.sh" ./entrypoint.sh)
    ];
    env = [
      "DOTNET_EnableDiagnostics=0"
      "RADARR__UPDATE__BRANCH=${branch}"
    ];
  };
in
{
  inherit
    version
    source
    systems
    sources
    package
    image
    ;
}
