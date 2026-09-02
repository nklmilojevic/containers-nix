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

  # renovate: datasource=custom.servarr-develop depName=lidarr versioning=loose
  version = "3.1.4.5029";
  source = "https://github.com/Lidarr/Lidarr";
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  updateUrl =
    arch:
    "https://lidarr.servarr.com/v1/update/${branch}/updatefile?version=${version}&os=linux&runtime=netcore&arch=${arch}";

  sources = {
    lidarr.name = "Lidarr.${branch}.${version}.linux-core.tar.gz";
    lidarr.urls = {
      x86_64-linux = updateUrl "x64";
      aarch64-linux = updateUrl "arm64";
    };
  };

  package = mkServarr {
    pname = name;
    binary = "Lidarr";
    inherit version branch;
    src = fetchSource sources hashes "lidarr";
    extraLibs = [ pkgs.chromaprint ];
    removeFiles = [ "fpcalc" ];
  };

  image = mkImage {
    inherit name version source;
    contents = [
      package
      (rootFile "/entrypoint.sh" ./entrypoint.sh)
      pkgs.chromaprint
      pkgs.ffmpeg-headless
    ];
    env = [
      "DOTNET_EnableDiagnostics=0"
      "LIDARR__UPDATE__BRANCH=${branch}"
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
