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

  # renovate: datasource=custom.sonarr-develop depName=sonarr versioning=loose
  version = "4.0.19.3009";
  source = "https://github.com/Sonarr/Sonarr";
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  updateUrl =
    arch:
    "https://services.sonarr.tv/v1/update/${branch}/download?version=${version}&os=linux&runtime=netcore&arch=${arch}";

  sources = {
    sonarr.name = "Sonarr.${branch}.${version}.linux-core.tar.gz";
    sonarr.urls = {
      x86_64-linux = updateUrl "x64";
      aarch64-linux = updateUrl "arm64";
    };
  };

  package = mkServarr {
    pname = name;
    binary = "Sonarr";
    inherit version branch;
    src = fetchSource sources hashes "sonarr";

  };

  image = mkImage {
    inherit name version source;
    contents = [
      package
      (rootFile "/entrypoint.sh" ./entrypoint.sh)

    ];
    env = [
      "DOTNET_EnableDiagnostics=0"
      "SONARR__UPDATE__BRANCH=${branch}"
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
