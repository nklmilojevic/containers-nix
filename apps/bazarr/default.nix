{
  pkgs,
  lib,
  name,
  helpers,
}:
let
  inherit (helpers) fetchSource mkImage rootFile;
  hashes = helpers.readHashes ./.;

  # renovate: datasource=github-releases depName=morpheus65535/bazarr
  version = "v1.6.0";
  source = "https://github.com/morpheus65535/bazarr";
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  sources.bazarr = {
    name = "bazarr-${version}.zip";
    urls = lib.genAttrs systems (
      _: "https://github.com/morpheus65535/bazarr/releases/download/${version}/bazarr.zip"
    );
  };

  # Same interpreter and compiled dependencies as nixpkgs bazarr; pure-Python
  # dependencies are vendored in libs/ inside the release zip.
  python = pkgs.python313.withPackages (
    ps: with ps; [
      lxml
      numpy
      pillow
      psycopg2
      setuptools
      webrtcvad
    ]
  );

  package = pkgs.stdenv.mkDerivation {
    pname = name;
    version = lib.removePrefix "v" version;
    src = fetchSource sources hashes "bazarr";
    dontUnpack = true;
    nativeBuildInputs = with pkgs; [
      unzip
      makeWrapper
    ];
    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/bazarr $out/bin
      unzip -q $src -d $out/share/bazarr
      rm -rf $out/share/bazarr/bin
      makeWrapper ${python}/bin/python $out/bin/bazarr \
        --add-flags $out/share/bazarr/bazarr.py \
        --prefix PATH : ${
          lib.makeBinPath (
            with pkgs;
            [
              ffmpeg-headless
              mediainfo
              unrar
            ]
          )
        }
      runHook postInstall
    '';
  };

  image = mkImage {
    inherit name version source;
    contents = with pkgs; [
      package
      ffmpeg-headless
      mediainfo
      unrar
      (rootFile "/entrypoint.sh" ./entrypoint.sh)
    ];
    env = [
      "BAZARR__PORT=6767"
      "BAZARR_PACKAGE_AUTHOR=nklmilojevic"
      "BAZARR_PACKAGE_VERSION=${version}"
      "BAZARR_VERSION=${version}"
      "PYTHONDONTWRITEBYTECODE=1"
      "PYTHONUNBUFFERED=1"
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
