{
  pkgs,
  lib,
  name,
  helpers,
}:
let
  inherit (helpers) fetchSource mkImage rootDir;
  hashes = helpers.readHashes ./.;
  # Non-flat hash, kept out of hashes.json so scripts/update-hashes.sh does not
  # overwrite it. Regenerate from frontend/package-lock.json in the release
  # tarball with: nix run nixpkgs#prefetch-npm-deps -- package-lock.json
  npmDeps = lib.importJSON ./npm-deps.json;

  # Pinned by hand: fork of hms-homelab/hms-cpap carrying the multi-EVE sidecar
  # fix and the nklmilojevic/hms-cpapdash-parser pin. Renovate does not manage
  # this version (semver ranks 4.9.9 above the 4.9.9-nkl.N prereleases).
  version = "v4.9.9-nkl.3";
  cpapdashParserVersion = "v2026.1.10-nkl.1";
  minizVersion = "3.0.2";
  hmsSharedVersion = "v1.6.9";
  source = "https://github.com/nklmilojevic/hms-cpap";
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  both = url: {
    x86_64-linux = url;
    aarch64-linux = url;
  };

  # Everything CMake would otherwise pull over the network via FetchContent.
  sources = {
    hms-cpap = {
      name = "hms-cpap-${version}.tar.gz";
      urls = both "${source}/archive/refs/tags/${version}.tar.gz";
    };
    cpapdash-parser = {
      name = "hms-cpapdash-parser-${cpapdashParserVersion}.tar.gz";
      urls = both "https://github.com/nklmilojevic/hms-cpapdash-parser/archive/refs/tags/${cpapdashParserVersion}.tar.gz";
    };
    miniz = {
      name = "miniz-${minizVersion}.tar.gz";
      urls = both "https://github.com/richgel999/miniz/archive/refs/tags/${minizVersion}.tar.gz";
    };
    hms-shared = {
      name = "hms-shared-${hmsSharedVersion}.tar.gz";
      urls = both "https://github.com/hms-homelab/hms-shared/archive/refs/tags/${hmsSharedVersion}.tar.gz";
    };
  };

  src = fetchSource sources hashes "hms-cpap";
  srcRoot = "hms-cpap-${lib.removePrefix "v" version}";

  frontend = pkgs.buildNpmPackage {
    pname = "hms-cpap-frontend";
    inherit version src;
    sourceRoot = "${srcRoot}/frontend";
    nodejs = pkgs.nodejs_22;
    npmDepsHash = npmDeps.frontendNpmDeps;
    # Upstream's lockfile only records the x86_64 esbuild binary; the vendored
    # copy adds the aarch64 one so the build works on both architectures.
    postPatch = ''
      cp ${./frontend-package-lock.json} package-lock.json
    '';
    npmFlags = [ "--ignore-scripts" ];
    env = {
      NG_CLI_ANALYTICS = "false";
      CI = "true";
    };
    installPhase = ''
      runHook preInstall
      cp -r dist/frontend/browser $out
      runHook postInstall
    '';
  };

  package = pkgs.stdenv.mkDerivation {
    pname = "hms-cpap";
    inherit version src;
    sourceRoot = srcRoot;

    nativeBuildInputs = with pkgs; [
      cmake
      pkg-config
    ];
    buildInputs = with pkgs; [
      brotli
      c-ares
      curl
      drogon
      fmt
      hiredis
      jsoncpp
      libharu
      libpqxx
      libuuid
      mariadb-connector-c
      nlohmann_json
      openssl
      paho-mqtt-c
      paho-mqtt-cpp
      postgresql
      spdlog
      sqlite
      yaml-cpp
      zlib
      zstd
    ];

    preConfigure = ''
      mkdir -p deps/cpapdash_parser deps/miniz deps/hms_shared
      tar xzf ${fetchSource sources hashes "cpapdash-parser"} -C deps/cpapdash_parser --strip-components=1
      tar xzf ${fetchSource sources hashes "miniz"} -C deps/miniz --strip-components=1
      tar xzf ${fetchSource sources hashes "hms-shared"} -C deps/hms_shared --strip-components=1
      chmod -R u+w deps
      cmakeFlagsArray+=(
        "-DFETCHCONTENT_SOURCE_DIR_CPAPDASH_PARSER=$PWD/deps/cpapdash_parser"
        "-DFETCHCONTENT_SOURCE_DIR_MINIZ=$PWD/deps/miniz"
        "-DFETCHCONTENT_SOURCE_DIR_HMS_SHARED=$PWD/deps/hms_shared"
      )
    '';

    cmakeFlags = [
      "-DBUILD_TESTS=OFF"
      "-DBUILD_WITH_WEB=ON"
      "-DBUILD_WITH_MYSQL=ON"
      "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
      "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    ];
    buildFlags = [ "hms_cpap" ];

    installPhase = ''
      runHook preInstall
      install -Dm755 hms_cpap $out/bin/hms_cpap
      runHook postInstall
    '';
  };

  image = mkImage {
    inherit name version source;
    contents = [
      package
      (rootDir "/home/cpap/static/browser" frontend)
    ];
    env = [
      "HMS_CPAP_DATA_DIR=/config"
      "HOME=/home/cpap"
    ];
    fakeRootCommands = ''
      rm -f ./etc/passwd ./etc/group
      printf 'root:x:0:0:root:/root:/bin/sh\nnobody:x:65534:65534:nobody:/var/empty:/bin/sh\ncpap:x:1000:1000:cpap:/home/cpap:/bin/bash\n' > ./etc/passwd
      printf 'root:x:0:\nnobody:x:65534:\ncpap:x:1000:\n' > ./etc/group
      mkdir -p ./data/cpap_archive ./tmp/hms-cpap ./usr/local/bin
      chown -R 1000:1000 ./data ./tmp/hms-cpap ./config ./home/cpap
      ln -s /bin/hms_cpap ./usr/local/bin/hms_cpap
    '';
    config = {
      User = "1000:1000";
      WorkingDir = "/home/cpap";
      Entrypoint = [ "/usr/local/bin/hms_cpap" ];
      ExposedPorts = {
        "8893/tcp" = { };
      };
    };
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
