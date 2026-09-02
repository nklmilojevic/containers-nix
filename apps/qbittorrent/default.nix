{
  pkgs,
  lib,
  name,
  helpers,
}:
let
  inherit (helpers)
    fetchSource
    mkImage
    rootFile
    rootDir
    ;
  hashes = helpers.readHashes ./.;

  # renovate: datasource=custom.qbittorrent depName=qbittorrent
  version = "5.2.3";
  # renovate: datasource=custom.libtorrent depName=libtorrent versioning=loose
  libtorrentVersion = "2.0.14";
  # renovate: datasource=github-releases depName=ludviglundgren/qbittorrent-cli
  cliVersion = "v2.3.0";
  source = "https://github.com/qbittorrent/qBittorrent";
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  staticUrl =
    arch:
    "https://github.com/userdocs/qbittorrent-nox-static/releases/download/release-${version}_v${libtorrentVersion}/${arch}-qbittorrent-nox";
  cliUrl =
    arch:
    "https://github.com/ludviglundgren/qbittorrent-cli/releases/download/${cliVersion}/qbittorrent-cli_${lib.removePrefix "v" cliVersion}_linux_${arch}.tar.gz";

  sources = {
    qbittorrent.urls = {
      x86_64-linux = staticUrl "x86_64";
      aarch64-linux = staticUrl "aarch64";
    };
    qbittorrent-cli.urls = {
      x86_64-linux = cliUrl "amd64";
      aarch64-linux = cliUrl "arm64";
    };
  };

  package = pkgs.stdenv.mkDerivation {
    pname = "qbittorrent-nox";
    inherit version;
    src = fetchSource sources hashes "qbittorrent";
    dontUnpack = true;
    installPhase = ''
      runHook preInstall
      install -Dm755 $src $out/bin/qbittorrent-nox
      runHook postInstall
    '';
  };

  cli = pkgs.stdenv.mkDerivation {
    pname = "qbittorrent-cli";
    version = lib.removePrefix "v" cliVersion;
    src = fetchSource sources hashes "qbittorrent-cli";
    sourceRoot = ".";
    installPhase = ''
      runHook preInstall
      install -Dm755 qbt $out/bin/qbt
      runHook postInstall
    '';
  };

  image = mkImage {
    inherit name version source;
    contents = with pkgs; [
      package
      cli
      _7zz
      (python3.override {
        stripConfig = true;
        stripTests = true;
        stripIdlelib = true;
        stripTkinter = true;
        rebuildBytecode = false;
      })
      unrar
      (rootFile "/entrypoint.sh" ./entrypoint.sh)
      (rootDir "/defaults" ./defaults)
    ];
    env = [
      "QBT_CONFIRM_LEGAL_NOTICE=1"
      "XDG_CONFIG_HOME=/config"
      "XDG_DATA_HOME=/config"
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
