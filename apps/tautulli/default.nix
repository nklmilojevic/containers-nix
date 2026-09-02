{
  pkgs,
  lib,
  name,
  helpers,
}:
let
  inherit (helpers) fetchSource mkImage rootFile;
  hashes = helpers.readHashes ./.;

  # renovate: datasource=github-releases depName=Tautulli/Tautulli
  version = "2.18.1";
  source = "https://github.com/Tautulli/Tautulli";
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  sources.tautulli = {
    name = "tautulli-${version}.tar.gz";
    urls = lib.genAttrs systems (_: "https://github.com/Tautulli/Tautulli/archive/v${version}.tar.gz");
  };

  # nixpkgs recipe (writes branch.txt/version.txt like the Dockerfile), upstream source.
  package = pkgs.tautulli.overrideAttrs (_: {
    inherit version;
    src = fetchSource sources hashes "tautulli";
  });

  image = mkImage {
    inherit name version source;
    contents = [
      package
      (rootFile "/entrypoint.sh" ./entrypoint.sh)
    ];
    env = [
      "TAUTULLI_DOCKER=True"
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
