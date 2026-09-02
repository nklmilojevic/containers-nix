{
  pkgs,
  lib,
  name,
  helpers,
}:
let
  # Vendored source under ./addon; kept in step by hand with the fork.
  version = "dev";
  source = "https://github.com/nklmilojevic/containers/tree/main/apps/petkit-local-dev";
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  sources = { };

  petkit = import ../../lib/petkit.nix { inherit pkgs lib helpers; } {
    inherit name version source;
    addon = ./addon;
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
