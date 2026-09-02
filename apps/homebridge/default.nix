{
  pkgs,
  lib,
  name,
  helpers,
}:
let
  inherit (helpers) mkImage;
  # Non-flat hashes live outside hashes.json so scripts/update-hashes.sh does
  # not overwrite them. Regenerate with:
  #   nix shell nixpkgs#nodejs_22 -c npm install --package-lock-only --ignore-scripts --omit=dev
  #   nix run nixpkgs#prefetch-npm-deps -- package-lock.json
  npmDeps = lib.importJSON ./npm-deps.json;

  # renovate: datasource=npm depName=homebridge
  version = "2.4.0";
  # renovate: datasource=npm depName=homebridge-config-ui-x
  uiVersion = "5.29.0";
  # renovate: datasource=npm depName=homebridge-unifi-protect
  protectVersion = "8.1.0";
  # renovate: datasource=github-releases depName=jellyfin/jellyfin-ffmpeg
  jellyfinFfmpegVersion = "v7.1.4-3";
  source = "https://github.com/homebridge/homebridge";
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  sources = { };

  nodejs = pkgs.nodejs_22;

  # The three npm packages pinned in package.json / package-lock.json, laid out
  # like a global install under /lib/node_modules (homebridge's default plugin
  # search path relative to the node binary).
  package = pkgs.buildNpmPackage {
    pname = "homebridge-bundle";
    inherit version nodejs;
    src = lib.fileset.toSource {
      root = ./.;
      fileset = lib.fileset.unions [
        ./package.json
        ./package-lock.json
      ];
    };
    npmDepsHash = npmDeps.npmDeps;
    npmFlags = [
      "--ignore-scripts"
      "--omit=dev"
    ];
    dontNpmBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib $out/bin
      cp -r node_modules $out/lib/node_modules
      for bin in homebridge hb-service; do
        ln -s ../lib/node_modules/.bin/$bin $out/bin/$bin
      done
      runHook postInstall
    '';
    passthru = {
      inherit uiVersion protectVersion;
    };
  };

  jellyfin-ffmpeg = pkgs.jellyfin-ffmpeg;

  image = mkImage {
    inherit name version source;
    contents = [
      package
      nodejs
      jellyfin-ffmpeg
    ];
    fakeRootCommands = ''
      mkdir -p ./usr/lib/jellyfin-ffmpeg
      ln -s /lib/node_modules ./usr/lib/node_modules
      ln -s /bin/ffmpeg ./usr/lib/jellyfin-ffmpeg/ffmpeg
      ln -s /bin/ffprobe ./usr/lib/jellyfin-ffmpeg/ffprobe
    '';
    config = {
      Entrypoint = [
        "/bin/catatonit"
        "--"
        "/bin/hb-service"
        "run"
        "--user-storage-path"
        "/config"
        "--stdout"
      ];
      ExposedPorts = {
        "8581/tcp" = { };
      };
    };
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
  jellyfinFfmpegVersion = lib.removePrefix "v" jellyfinFfmpegVersion;
}
