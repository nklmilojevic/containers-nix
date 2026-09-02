{
  description = "Container images built with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;

      linuxSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      allSystems = linuxSystems ++ [
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      appNames = builtins.attrNames (
        lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./apps)
      );

      importPkgs =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

      # Instantiate every app for one Linux system.
      mkApps =
        system:
        let
          pkgs = importPkgs system;
          helpers = import ./lib { inherit pkgs lib; };
        in
        lib.genAttrs appNames (
          name:
          import ./apps/${name} {
            inherit
              pkgs
              lib
              name
              helpers
              ;
          }
        );

      # Pure metadata; evaluated once and independent of the build host.
      meta = lib.mapAttrs (_: app: {
        inherit (app) version source sources;
        platforms = map helpersPure.systemToPlatform app.systems;
        systems = app.systems;
      }) (mkApps "x86_64-linux");

      helpersPure = import ./lib/pure.nix { inherit lib; };
    in
    {
      inherit meta;

      packages = lib.genAttrs linuxSystems (
        system:
        let
          apps = lib.filterAttrs (_: app: builtins.elem system app.systems) (mkApps system);
        in
        lib.mapAttrs (_: app: app.image) apps
        // lib.mapAttrs' (name: app: lib.nameValuePair "${name}-package" app.package) apps
      );

      devShells = lib.genAttrs allSystems (
        system:
        let
          pkgs = importPkgs system;
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              go_1_27
              gh
              jq
              skopeo
              nixfmt
              shellcheck
            ];
          };
        }
      );

      formatter = lib.genAttrs allSystems (system: (importPkgs system).nixfmt);
    };
}
