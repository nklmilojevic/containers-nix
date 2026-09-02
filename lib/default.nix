{ pkgs, lib }:
let
  system = pkgs.stdenv.hostPlatform.system;
in
rec {
  inherit (import ./pure.nix { inherit lib; }) systemToPlatform;

  # Read apps/<name>/hashes.json, tolerating a missing file so that
  # `nix eval .#meta` works before hashes have been generated.
  readHashes =
    dir:
    if builtins.pathExists (dir + "/hashes.json") then lib.importJSON (dir + "/hashes.json") else { };

  # sources = { <name> = { urls = { <system> = url; }; }; }
  # hashes  = { <name> = { <system> = "sha256-..."; }; }
  fetchSource =
    sources: hashes: name:
    pkgs.fetchurl (
      {
        url = sources.${name}.urls.${system};
        hash = hashes.${name}.${system} or lib.fakeHash;
      }
      // lib.optionalAttrs (sources.${name} ? name) { inherit (sources.${name}) name; }
    );

  # Place a file from the repo at an absolute path inside the image.
  rootFile =
    path: src:
    pkgs.runCommand "root-file-${baseNameOf path}" { } ''
      install -Dm755 ${src} $out${path}
    '';

  rootDir =
    path: src:
    pkgs.runCommand "root-dir-${baseNameOf path}" { } ''
      mkdir -p $out${builtins.dirOf path}
      cp -r ${src} $out${path}
    '';

  # bashNonInteractive also provides /bin/sh; the interactive build drags in ncurses and readline.
  baseContents = with pkgs; [
    bashNonInteractive
    cacert
    catatonit
    coreutils
    curl
    jq
    (nano.override { enableTiny = true; })
    tzdata
    dockerTools.usrBinEnv
    dockerTools.caCertificates
    dockerTools.fakeNss
  ];

  mkImage =
    {
      name,
      version,
      source,
      contents ? [ ],
      env ? [ ],
      fakeRootCommands ? "",
      config ? { },
      maxLayers ? 100,
    }:
    pkgs.dockerTools.streamLayeredImage {
      inherit name maxLayers;
      tag = version;
      contents = baseContents ++ contents;
      fakeRootCommands = ''
        mkdir -p ./config ./tmp ./etc
        chown 65534:65534 ./config
        chmod 1777 ./tmp
        ln -s ../share/zoneinfo ./etc/zoneinfo
        ${fakeRootCommands}
      '';
      config = {
        User = "65534:65534";
        WorkingDir = "/config";
        Volumes = {
          "/config" = { };
        };
        Entrypoint = [
          "/bin/catatonit"
          "--"
          "/entrypoint.sh"
        ];
        Env = [
          "PATH=/usr/local/bin:/usr/bin:/bin"
          "HOME=/config"
          "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
          "TZDIR=/share/zoneinfo"
        ]
        ++ env;
        Labels = {
          "org.opencontainers.image.title" = name;
          "org.opencontainers.image.version" = version;
          "org.opencontainers.image.source" = source;
        };
      }
      // config;
    };
}
