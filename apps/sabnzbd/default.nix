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

  # renovate: datasource=github-releases depName=sabnzbd/sabnzbd
  version = "5.1.2";
  source = "https://github.com/sabnzbd/sabnzbd";
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  sources.sabnzbd = {
    name = "SABnzbd-${version}-src.tar.gz";
    urls = lib.genAttrs systems (
      _: "https://github.com/sabnzbd/sabnzbd/releases/download/${version}/SABnzbd-${version}-src.tar.gz"
    );
  };

  # nixpkgs supplies the Python environment; the app comes from the upstream release tarball.
  package = pkgs.sabnzbd.overrideAttrs (_: {
    inherit version;
    src = fetchSource sources hashes "sabnzbd";
  });

  image = mkImage {
    inherit name version source;
    contents = with pkgs; [
      package
      par2cmdline-turbo
      unrar
      _7zz
      (rootFile "/entrypoint.sh" ./entrypoint.sh)
      (rootDir "/defaults" ./defaults)
    ];
    env = [
      "SABNZBD__ADDRESS=[::]"
      "SABNZBD__PORT=8080"
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
