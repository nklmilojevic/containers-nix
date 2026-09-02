{
  pkgs,
  lib,
  name,
  helpers,
}:
let
  inherit (helpers) fetchSource mkImage rootFile;
  mkServarr = import ../../lib/servarr.nix { inherit pkgs lib; };
  branch = "develop";
  hashes = helpers.readHashes ./.;

  # renovate: datasource=custom.readarr-develop depName=readarr versioning=loose
  version = "0.4.18.2805";
  source = "https://github.com/Readarr/Readarr";
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  updateUrl =
    arch:
    "https://readarr.servarr.com/v1/update/${branch}/updatefile?version=${version}&os=linux&runtime=netcore&arch=${arch}";

  sources = {
    readarr.name = "Readarr.${branch}.${version}.linux-core.tar.gz";
    readarr.urls = {
      x86_64-linux = updateUrl "x64";
      aarch64-linux = updateUrl "arm64";
    };
  };

  package = mkServarr {
    pname = name;
    binary = "Readarr";
    inherit version branch;
    src = fetchSource sources hashes "readarr";

  };

  image = mkImage {
    inherit name version source;
    contents = [
      package
      (rootFile "/entrypoint.sh" ./entrypoint.sh)

    ];
    env = [
      "DOTNET_EnableDiagnostics=0"
      "READARR__UPDATE__BRANCH=${branch}"
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
