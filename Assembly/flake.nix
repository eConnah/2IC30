{
  description = "Safe ARM32 Assembly Environment";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];

      perSystem = { pkgs, ... }: 
        let
          # 1. Compilation Script
          compileScript = pkgs.writeShellScriptBin "32compile" ''
            if [ -z "$1" ]; then
              echo "Usage: 32compile <file.s>"
              exit 1
            fi

            INPUT="$1"
            OUTPUT="''${INPUT%.*}"

            echo "🛠️ Compiling $INPUT..."
            armv7l-unknown-linux-gnueabihf-gcc -static -nostdlib -e main -g -o "$OUTPUT" "$INPUT"

            if [ $? -eq 0 ]; then
              echo "✅ Compiled: $OUTPUT"
              echo "👉 To run: 32wrap $OUTPUT"
            else
              echo "❌ Compilation failed."
              exit 1
            fi
          '';

          # 2. Bubblewrap/QEMU Execution Script
          wrapScript = pkgs.writeShellScriptBin "32wrap" ''
            if [ -z "$1" ]; then
              echo "Usage: 32wrap <executable>"
              exit 1
            fi

            BIN="$1"

            echo "🚀 Running $BIN in READ-ONLY mode..."
            # --ro-bind / /  => Mounts your entire drive as READ ONLY
            # --dev /dev     => Allows printing to your terminal screen
            ${pkgs.bubblewrap}/bin/bwrap --ro-bind / / --dev /dev ${pkgs.qemu}/bin/qemu-arm "./$BIN"
          '';

        in {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.pkgsCross.armv7l-hf-multiplatform.buildPackages.gcc
            pkgs.qemu
            pkgs.bubblewrap
            compileScript
            wrapScript
          ];          

          shellHook = ''
            echo "================================================="
            echo " 🐧 Full Linux ARM32 Assembly Environment Ready! 🐧"
            echo "================================================="
            echo "Available Commands:"
            echo "  1. Compile   : 32compile file.s"
            echo "  2. BWrap Run : 32wrap file"
            echo "================================================="
          '';
        };
      };
    };
}
