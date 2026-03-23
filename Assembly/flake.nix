{
  description = "Raspberry Pi Assembly Dev Environment (Full Linux GCC)";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      # Locked to Linux systems since macOS Darwin can't run Linux syscalls natively
      systems = [ "x86_64-linux" "aarch64-linux" ];

      perSystem = { pkgs, system, ... }: 
        let
          # Define our custom '32compile' command
          compileScript = pkgs.writeShellScriptBin "32compile" ''
            # Check if the user actually provided a file
            if [ -z "$1" ]; then
              echo "⚠️  Usage: 32compile <filename.s>"
              exit 1
            fi

            INPUT="$1"
            # Bash string manipulation to strip the extension for the output name
            OUTPUT="''${INPUT%.*}"

            echo "🛠️  Compiling $INPUT -> $OUTPUT..."
            armv7l-unknown-linux-gnueabihf-gcc -static -nostdlib -e main -g -o "$OUTPUT" "$INPUT"

            # Check if compilation was successful ($? is the exit code of the last command)
            if [ $? -eq 0 ]; then
              echo "✅ Success! Run your program with:"
              echo "   qemu-arm ./$OUTPUT"
            else
              echo "❌ Compilation failed. Check your assembly syntax!"
            fi
          '';
        in {
        
        devShells.default = pkgs.mkShell {
          packages = [
            # The full Linux cross-compiler for 32-bit ARM (armhf)
            pkgs.pkgsCross.armv7l-hf-multiplatform.buildPackages.gcc
            pkgs.qemu
            # Inject our custom command into the shell environment
            compileScript
          ];

          shellHook = ''
            echo "================================================="
            echo " 🐧 Full Linux ARM32 Assembly Environment Ready! 🐧"
            echo "================================================="
            echo "Available Commands:"
            echo "  1. Compile : 32compile file.s"
            echo "  2. Execute : qemu-arm ./file"
            echo "================================================="
          '';
        };

      };
    };
}
