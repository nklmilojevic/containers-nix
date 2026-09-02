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

  # renovate: datasource=custom.servarr-develop depName=prowlarr versioning=loose
  version = "2.6.3.5592";
  source = "https://github.com/Prowlarr/Prowlarr";
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  updateUrl =
    arch:
    "https://prowlarr.servarr.com/v1/update/${branch}/updatefile?version=${version}&os=linux&runtime=netcore&arch=${arch}";

  sources = {
    prowlarr.name = "Prowlarr.${branch}.${version}.linux-core.tar.gz";
    prowlarr.urls = {
      x86_64-linux = updateUrl "x64";
      aarch64-linux = updateUrl "arm64";
    };
  };

  package = mkServarr {
    pname = name;
    binary = "Prowlarr";
    inherit version branch;
    src = fetchSource sources hashes "prowlarr";

  };

  image = mkImage {
    inherit name version source;
    contents = [
      package
      (rootFile "/entrypoint.sh" ./entrypoint.sh)

    ];
    env = [
      "DOTNET_EnableDiagnostics=0"
      "PROWLARR__UPDATE__BRANCH=${branch}"
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
