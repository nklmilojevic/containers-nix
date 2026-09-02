# Shared definition for the petkit-local images: a nixpkgs Python environment
# covering addon/requirements.txt plus the petkit_local package from `addon`.
{
  pkgs,
  lib,
  helpers,
}:
{
  name,
  version,
  source,
  addon,
}:
let
  python = pkgs.python3;

  # Not packaged in nixpkgs; upstream pins its dependencies with == so relax them.
  amqtt = python.pkgs.buildPythonPackage rec {
    pname = "amqtt";
    version = "0.11.4";
    pyproject = true;
    src = pkgs.fetchPypi {
      inherit pname version;
      hash = "sha256-q2/1Sc4i2vpv6abHw4sqvZhn0w32ASEIVEbYKQIwp58=";
    };
    build-system = with python.pkgs; [
      hatchling
      hatch-vcs
      uv-dynamic-versioning
    ];
    pythonRelaxDeps = true;
    dependencies = with python.pkgs; [
      dacite
      passlib
      psutil
      pyyaml
      transitions
      typer
      websockets
    ];
    doCheck = false;
    pythonImportsCheck = [ "amqtt" ];
  };

  env = python.withPackages (
    ps: with ps; [
      aiohttp
      amqtt
      aiomqtt
      cryptography
      pyelftools
      sqlalchemy
      greenlet
      aiosqlite
      jinja2
      aiohttp-jinja2
    ]
  );

  app = pkgs.runCommand "${name}-${version}" { } ''
    mkdir -p $out/opt/petkit-local
    cp -r ${addon}/petkit_local $out/opt/petkit-local/petkit_local
  '';
in
{
  package = env;
  image = helpers.mkImage {
    inherit name version source;
    contents = with pkgs; [
      env
      app
      ffmpeg-headless
      go2rtc
    ];
    env = [
      "PYTHONPATH=/opt/petkit-local"
      "PYTHONDONTWRITEBYTECODE=1"
      "PYTHONUNBUFFERED=1"
    ];
    fakeRootCommands = ''
      mkdir -p ./data ./media/petkit
      chown -R 1000:1000 ./data ./media/petkit
    '';
    config = {
      User = "1000";
      WorkingDir = "/data";
      Volumes = {
        "/data" = { };
      };
      ExposedPorts = {
        "8080/tcp" = { };
        "8099/tcp" = { };
        "8443/tcp" = { };
        "9000/tcp" = { };
      };
      Entrypoint = [
        "/bin/catatonit"
        "--"
        "python3"
        "-m"
        "petkit_local.main"
      ];
    };
  };
}
