{
  pkgs,
  lib,
  name,
  helpers,
}:
let
  inherit (helpers) fetchSource mkImage rootFile;
  hashes = helpers.readHashes ./.;

  # renovate: datasource=github-releases depName=stashapp/stash
  version = "v0.31.1";
  source = "https://github.com/stashapp/stash";
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  releaseUrl = file: "https://github.com/stashapp/stash/releases/download/${version}/${file}";
  sources.stash = {
    name = "stash-${version}";
    urls = {
      x86_64-linux = releaseUrl "stash-linux";
      aarch64-linux = releaseUrl "stash-linux-arm64v8";
    };
  };

  package = pkgs.stdenv.mkDerivation {
    pname = name;
    version = lib.removePrefix "v" version;
    src = fetchSource sources hashes "stash";
    dontUnpack = true;
    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = [ pkgs.stdenv.cc.cc.lib ];
    installPhase = ''
      runHook preInstall
      install -Dm755 $src $out/bin/stash
      runHook postInstall
    '';
  };

  image = mkImage {
    inherit name version source;
    contents = with pkgs; [
      package
      ffmpeg-headless
      uv
      (python3.override {
        stripConfig = true;
        stripTests = true;
        stripIdlelib = true;
        stripTkinter = true;
        rebuildBytecode = false;
      })
      (rootFile "/entrypoint.sh" ./entrypoint.sh)
    ];
    env = [
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
