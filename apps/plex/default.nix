{
  pkgs,
  lib,
  name,
  helpers,
}:
let
  inherit (helpers) fetchSource mkImage rootFile;
  hashes = helpers.readHashes ./.;

  # renovate: datasource=custom.plex depName=plex versioning=loose
  version = "1.43.3.10896-cb3ebc72d";
  source = "https://github.com/plexinc/pms-docker";
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  debUrl =
    arch:
    "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_${arch}.deb";

  sources = {
    plex.urls = {
      x86_64-linux = debUrl "amd64";
      aarch64-linux = debUrl "arm64";
    };
  };

  # Plex ships its own libraries with $ORIGIN rpaths; the only thing it needs
  # from the host is the ELF interpreter, which the image provides by
  # symlinking the FHS loader path to nixpkgs glibc (see fakeRootCommands).
  package = pkgs.stdenv.mkDerivation {
    pname = "plexmediaserver";
    inherit version;
    src = fetchSource sources hashes "plex";
    nativeBuildInputs = [ pkgs.dpkg ];
    unpackPhase = ''
      dpkg-deb -x $src .
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib
      cp -dr --no-preserve=ownership usr/lib/plexmediaserver $out/lib/
      chmod -R u+w,a+rX $out/lib/plexmediaserver
      runHook postInstall
    '';
    dontPatchShebangs = true;
    dontStrip = true;
    dontPatchELF = true;
    dontAutoPatchelf = true;
  };

  dynamicLinker = pkgs.stdenv.cc.bintools.dynamicLinker;

  image = mkImage {
    inherit name version source;
    contents = with pkgs; [
      package
      findutils
      gnused
      util-linux
      xmlstarlet
      (rootFile "/entrypoint.sh" ./entrypoint.sh)
    ];
    env = [
      "NVIDIA_DRIVER_CAPABILITIES=compute,video,utility"
      "PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR=/config/Library/Application Support"
      "PLEX_MEDIA_SERVER_HOME=${package}/lib/plexmediaserver"
      "PLEX_MEDIA_SERVER_MAX_PLUGIN_PROCS=6"
      "PLEX_MEDIA_SERVER_INFO_VENDOR=Docker"
      "PLEX_MEDIA_SERVER_INFO_DEVICE=Docker Container (nklmilojevic)"
    ];
    fakeRootCommands = ''
      mkdir -p ./transcode ./lib64
      chown 65534:65534 ./transcode
      ln -sf ${dynamicLinker} ./lib64/${baseNameOf dynamicLinker}
      [ -e ./lib/${baseNameOf dynamicLinker} ] || ln -s ${dynamicLinker} ./lib/${baseNameOf dynamicLinker}
    '';
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
