{
  pkgs,
  lib,
  name,
  helpers,
}:
let
  inherit (helpers) fetchSource mkImage rootFile;
  hashes = helpers.readHashes ./.;

  # renovate: datasource=pypi depName=esphome
  version = "2026.8.2";
  # renovate: datasource=pypi depName=esphome-device-builder
  deviceBuilderVersion = "1.13.1";
  # renovate: datasource=pypi depName=esphome-device-builder-frontend
  deviceBuilderFrontendVersion = "0.1.317";
  source = "https://github.com/esphome/esphome";
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  both = url: {
    x86_64-linux = url;
    aarch64-linux = url;
  };

  sources = {
    esphome = {
      name = "esphome-${version}.tar.gz";
      urls = both "https://github.com/esphome/esphome/archive/refs/tags/${version}.tar.gz";
    };
    esphome-device-builder = {
      name = "esphome-device-builder-${deviceBuilderVersion}.tar.gz";
      urls = both "https://github.com/esphome/device-builder/archive/refs/tags/${deviceBuilderVersion}.tar.gz";
    };
    esphome-device-builder-frontend = {
      name = "esphome_device_builder_frontend-${deviceBuilderFrontendVersion}-py3-none-any.whl";
      urls = both "https://files.pythonhosted.org/packages/py3/e/esphome_device_builder_frontend/esphome_device_builder_frontend-${deviceBuilderFrontendVersion}-py3-none-any.whl";
    };
  };

  # The device builder pins an exact frontend version; take the published
  # wheel instead of nixpkgs' from-source build so the pin can be followed.
  deviceBuilderFrontend = pkgs.python3Packages.buildPythonPackage {
    pname = "esphome-device-builder-frontend";
    version = deviceBuilderFrontendVersion;
    format = "wheel";
    src = fetchSource sources hashes "esphome-device-builder-frontend";
    pythonImportsCheck = [ "esphome_device_builder_frontend" ];
  };

  # nixpkgs packaging (patches, relaxed pins, platformio wiring) with the
  # upstream source swapped to the pinned release.
  esphome = pkgs.esphome.overrideAttrs (old: {
    inherit version;
    src = fetchSource sources hashes "esphome";
    doCheck = false;
    doInstallCheck = false;
    meta = old.meta // {
      changelog = "${source}/releases/tag/${version}";
    };
  });

  deviceBuilder = (pkgs.esphome-device-builder.override { inherit esphome; }).overrideAttrs (old: {
    version = deviceBuilderVersion;
    src = fetchSource sources hashes "esphome-device-builder";
    propagatedBuildInputs = map (
      d: if (d.pname or "") == "esphome-device-builder-frontend" then deviceBuilderFrontend else d
    ) old.propagatedBuildInputs;
    doCheck = false;
    doInstallCheck = false;
    meta = old.meta // {
      changelog = "https://github.com/esphome/device-builder/releases/tag/${deviceBuilderVersion}";
    };
  });

  package = esphome;

  image = mkImage {
    inherit name version source;
    contents = with pkgs; [
      esphome
      deviceBuilder
      platformio-core
      git
      iputils
      openssh
      patch
      libusb1
      cairo
      file
      (rootFile "/entrypoint.sh" ./entrypoint.sh)
    ];
    env = [
      "PLATFORMIO_CORE_DIR=/cache/pio"
      "ESPHOME_BUILD_PATH=/cache/build"
      "ESPHOME_DATA_DIR=/cache/data"
      "ESPHOME_ESP_IDF_PREFIX=/cache/idf"
      "ESPHOME_SDK_NRF_PREFIX=/cache/sdk-nrf"
    ];
    fakeRootCommands = ''
      mkdir -p ./cache
      chown 65534:65534 ./cache
    '';
    config = {
      Cmd = [
        "dashboard"
        "/config"
      ];
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
