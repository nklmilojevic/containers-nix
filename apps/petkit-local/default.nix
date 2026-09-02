{
  pkgs,
  lib,
  name,
  helpers,
}:
let
  inherit (helpers) fetchSource;
  hashes = helpers.readHashes ./.;

  # Pinned by hand: the fork carries upstream's v2.1.0 tag as is and semver ranks
  # 2.1.0 above the 2.1.0-nkl.N fork prereleases, so Renovate must not manage this.
  version = "v2.1.0-nkl.3";
  source = "https://github.com/nklmilojevic/petkit-local";
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  sources.petkit-local = {
    name = "petkit-local-${version}.tar.gz";
    urls = lib.genAttrs systems (
      _: "https://github.com/nklmilojevic/petkit-local/archive/refs/tags/${version}.tar.gz"
    );
  };

  addon = pkgs.runCommand "petkit-local-addon-${version}" { } ''
    mkdir -p $out
    tar xzf ${fetchSource sources hashes "petkit-local"} -C $out --strip-components=2 \
      --wildcards '*/addon/petkit_local'
  '';

  petkit = import ../../lib/petkit.nix { inherit pkgs lib helpers; } {
    inherit
      name
      version
      source
      addon
      ;
  };
in
{
  inherit
    version
    source
    systems
    sources
    ;
  inherit (petkit) package image;
}
