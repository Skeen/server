{
  description = "Traggo UI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "traggo-ui";
          version = "0.1.0";

          src = ./.;

          yarnOfflineCache = pkgs.fetchYarnDeps {
            yarnLock = ./yarn.lock;
            sha256 = "sha256-BDQ7MgRWBRQQfjS5UCW3KJ0kJrkn4g9o4mU0ZH+vhX0=";
          };

          nativeBuildInputs = with pkgs; [
            yarn
            nodejs
            yarnConfigHook
            yarnBuildHook
          ];

          # Needed for newer Node.js versions with older crypto usage in dependencies
          env.NODE_OPTIONS = "--openssl-legacy-provider";

          # Reference the schema file from the parent directory
          # This will cause Nix to include it in the build context
          schemaFile = ../schema.graphql;

          # Run generation before the build (which is triggered by yarnBuildHook)
          preBuild = ''
            # Ensure the parent directory exists and link the schema file
            # In the Nix build sandbox, we are typically in /build/source
            # so ../ is /build, which is writable.
            ln -s $schemaFile ../schema.graphql
            yarn --offline generate
          '';

          installPhase = ''
            runHook preInstall
            cp -r build $out
            runHook postInstall
          '';
        };
      }
    );
}
