{
  pkgs,
  lib,
  name,
  helpers,
}:
let
  inherit (helpers) mkImage;
  # Version follows nixpkgs; the upstream image pinned the Alpine release instead.
  package = pkgs.openssh;
  version = package.version;
  source = "https://github.com/openssh/openssh-portable";
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  sources = { };

  # sshd re-execs itself and therefore must be started by absolute path.
  entrypoint = pkgs.runCommand "openssh-entrypoint" { } ''
    install -Dm755 ${./entrypoint.sh.in} $out/entrypoint.sh
    substituteInPlace $out/entrypoint.sh \
      --replace-fail "exec /bin/sshd" "exec ${package}/bin/sshd" \
      --replace-fail "@sftpServer@" "${package}/libexec/sftp-server"
    mkdir -p $out/etc/ssh
    touch $out/etc/ssh/sshd_config
  '';

  image = mkImage {
    inherit name version source;
    contents = [
      package
      pkgs.glibc.bin
      entrypoint
    ];
    env = [
      "PORT=2222"
      "USER_NAME=me"
      "HOME=/config"
    ];
    # Replace fakeNss's passwd/group with a "me" user (uid 1000) and keep
    # /etc/passwd group-writable so arbitrary uids can register themselves.
    fakeRootCommands = ''
      rm -f ./etc/passwd ./etc/group
      cat > ./etc/passwd <<'PASSWD'
      root:x:0:0:root:/root:/bin/bash
      me:x:1000:1000:me:/config:/bin/bash
      nobody:x:65534:65534:nobody:/var/empty:/bin/sh
      PASSWD
      cat > ./etc/group <<'GROUP'
      root:x:0:
      me:x:1000:
      nogroup:x:65534:
      GROUP
      chown 0:0 ./etc/passwd ./etc/group
      chmod 664 ./etc/passwd
      chmod 644 ./etc/group
      mkdir -p ./var/empty
      chown 1000:1000 ./config
    '';
    config = {
      User = "1000";
      ExposedPorts = {
        "2222/tcp" = { };
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
