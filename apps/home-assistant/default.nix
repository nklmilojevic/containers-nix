{
  pkgs,
  lib,
  name,
  helpers,
}:
let
  inherit (helpers) mkImage rootFile;

  # Components whose nixpkgs dependencies do not evaluate or do not build on
  # this revision (mostly test suites failing on Python 3.14).
  excludedComponents = [
    "raincloud"
    "sendgrid"
    "aquostv"
    "bizkaibus"
    "ephember"
    "etherscan"
    "heatmiser"
    "imap"
    "irish_rail_transport"
    "kef"
    "linode"
    "noaa_tides"
    "sinch"
    "upc_connect"
  ];
  components = lib.subtractLists excludedComponents pkgs.home-assistant.availableComponents;

  # Version follows nixpkgs; Home Assistant is the one app where the source
  # is not overridden because nixpkgs pins its dependency set per release.
  ha = pkgs.home-assistant.override { extraComponents = components; };
  version = ha.version;
  source = "https://github.com/home-assistant/core";
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  sources = { };

  componentPackages = lib.concatMap (c: (ha.getPackages c) ha.python3Packages) components;

  # nixpkgs only exposes component dependencies through passthru.pythonPath,
  # meant for a PYTHONPATH variable. With every component enabled that string
  # exceeds the kernel's single-argument limit, so build one interpreter whose
  # site-packages carries Home Assistant, its dependencies and all component
  # dependencies instead. Runtime installs (custom components) land in
  # /config/deps because Home Assistant runs outside a virtualenv.
  pythonEnv = ha.python3Packages.python.buildEnv.override {
    extraLibs = [ (ha.python3Packages.toPythonModule ha) ] ++ componentPackages;
    ignoreCollisions = true;
  };

  entrypoint = pkgs.replaceVars ./entrypoint.sh { python = "${pythonEnv}/bin/python3"; };

  package = ha;

  image = mkImage {
    inherit name version source;
    contents = with pkgs; [
      pythonEnv
      uv
      go2rtc
      ffmpeg-headless
      git
      openssh
      (rootFile "/entrypoint.sh" entrypoint)
    ];
    env = [
      "PYTHONDONTWRITEBYTECODE=1"
      "PYTHONUNBUFFERED=1"
      "UV_NO_CACHE=true"
    ];
    maxLayers = 120;
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
