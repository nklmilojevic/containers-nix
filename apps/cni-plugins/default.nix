{
  pkgs,
  lib,
  name,
  helpers,
}:
let
  inherit (helpers) fetchSource;
  hashes = helpers.readHashes ./.;

  # renovate: datasource=github-releases depName=containernetworking/plugins
  version = "v1.9.1";
  source = "https://github.com/containernetworking/plugins";
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  tarUrl =
    arch:
    "https://github.com/containernetworking/plugins/releases/download/${version}/cni-plugins-linux-${arch}-${version}.tgz";

  sources = {
    cni-plugins.urls = {
      x86_64-linux = tarUrl "amd64";
      aarch64-linux = tarUrl "arm64";
    };
  };

  package = pkgs.stdenv.mkDerivation {
    pname = "cni-plugins";
    version = lib.removePrefix "v" version;
    src = fetchSource sources hashes "cni-plugins";
    sourceRoot = ".";
    installPhase = ''
      runHook preInstall
      mkdir -p $out/plugins
      # the tarball has no top-level directory, so cwd also holds the build env-vars file
      rm -f env-vars
      cp -r ./. $out/plugins/
      runHook postInstall
    '';
  };

  image = pkgs.dockerTools.streamLayeredImage {
    inherit name;
    tag = lib.removePrefix "v" version;
    contents = with pkgs; [
      package
      bashNonInteractive
      coreutils
      rsync
      dockerTools.fakeNss
    ];
    config = {
      User = "0:0";
      Env = [
        "PATH=/bin"
        "CNI_BIN_DIR=/host/opt/cni/bin"
      ];
      Cmd = [
        "/bin/sh"
        "-c"
        "rsync -av --exclude=LICENSE --exclude=README.md /plugins/* $CNI_BIN_DIR"
      ];
      Labels = {
        "org.opencontainers.image.title" = name;
        "org.opencontainers.image.version" = lib.removePrefix "v" version;
        "org.opencontainers.image.source" = source;
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
}
