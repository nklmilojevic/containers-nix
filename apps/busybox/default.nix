{
  pkgs,
  lib,
  name,
  helpers,
}:
let
  # Version follows nixpkgs; there is no upstream artifact to pin separately.
  package = pkgs.pkgsStatic.busybox;
  version = package.version;
  source = "https://www.busybox.net";
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  sources = { };

  image = pkgs.dockerTools.streamLayeredImage {
    inherit name;
    tag = version;
    contents = [ package ];
    config = {
      Cmd = [ "sh" ];
      Env = [ "PATH=/bin:/sbin" ];
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
