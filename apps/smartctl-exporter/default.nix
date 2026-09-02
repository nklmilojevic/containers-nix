{
  pkgs,
  lib,
  name,
  helpers,
}:
let
  inherit (helpers) fetchSource;
  hashes = helpers.readHashes ./.;

  # renovate: datasource=github-releases depName=prometheus-community/smartctl_exporter
  version = "0.14.0";
  source = "https://github.com/prometheus-community/smartctl_exporter";
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  tarUrl =
    arch:
    "https://github.com/prometheus-community/smartctl_exporter/releases/download/v${version}/smartctl_exporter-${version}.linux-${arch}.tar.gz";

  sources = {
    smartctl-exporter.urls = {
      x86_64-linux = tarUrl "amd64";
      aarch64-linux = tarUrl "arm64";
    };
  };

  package = pkgs.stdenv.mkDerivation {
    pname = "smartctl_exporter";
    inherit version;
    src = fetchSource sources hashes "smartctl-exporter";
    installPhase = ''
      runHook preInstall
      install -Dm755 smartctl_exporter $out/bin/smartctl_exporter
      runHook postInstall
    '';
  };

  image = pkgs.dockerTools.streamLayeredImage {
    inherit name;
    tag = version;
    contents = with pkgs; [
      package
      smartmontools
      dockerTools.fakeNss
    ];
    config = {
      User = "65534:65534";
      Entrypoint = [ "/bin/smartctl_exporter" ];
      Env = [ "PATH=/bin" ];
      Labels = {
        "org.opencontainers.image.title" = name;
        "org.opencontainers.image.version" = version;
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
