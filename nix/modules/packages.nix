{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      system,
      ...
    }:
    let
      mkZed = import ../toolchain.nix { inherit inputs; };
      zed-editor = mkZed pkgs;
    in
    {
      packages = {
        default = zed-editor;
        debug = zed-editor.override { profile = "dev"; };
        remote-server =
          let
            inherit (zed-editor.passthru) craneLib commonArgs cargoArtifacts;
            version = (builtins.fromTOML (builtins.readFile ../../crates/zed/Cargo.toml)).package.version;
          in
          craneLib.buildPackage (
            commonArgs
            // {
              pname = "zed-remote-server";
              inherit version cargoArtifacts;
              cargoExtraArgs = "-p remote_server --locked";
              env = commonArgs.env // {
                ZED_RELEASE_CHANNEL = "stable";
                RELEASE_VERSION = version;
              };
              dontUseCmakeConfigure = true;
              installPhase = ''
                runHook preInstall
                install -D -m 755 "$TARGET_DIR/remote_server" "$out/bin/remote_server"
                runHook postInstall
              '';
            }
          );
      };
    }
    // lib.optionalAttrs (lib.hasSuffix "linux" system) {
      checks = {
        a11y-test = import ../tests/a11y.nix {
          inherit pkgs inputs;
        };
      }
      // import ../tests/sandboxing { inherit pkgs inputs; };
    };
}
