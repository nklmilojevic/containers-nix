{
  pkgs,
  lib,
  name,
  helpers,
}:
let
  inherit (helpers) mkImage rootFile rootDir;
  # Version follows nixpkgs; the upstream image pinned the Alpine package instead.
  package = pkgs.transmission_4;
  version = package.version;
  source = "https://github.com/transmission/transmission";
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  sources = { };

  image = mkImage {
    inherit name version source;
    contents = with pkgs; [
      package
      minijinja
      _7zz
      unrar
      (python3.override {
        stripConfig = true;
        stripTests = true;
        stripIdlelib = true;
        stripTkinter = true;
        rebuildBytecode = false;
      })
      (rootFile "/entrypoint.sh" ./entrypoint.sh)
      (rootDir "/defaults" ./defaults)
    ];
    env = [
      "XDG_CONFIG_HOME=/config"
      "XDG_DATA_HOME=/config"
      "TRANSMISSION_WEB_HOME=${package}/share/transmission/public_html"
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
