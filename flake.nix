{
  description = "Nix Develop Flake";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      perSystem = { pkgs, system, ... }: {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.jdk8_headless
          ];

          shellHook = ''
            echo "Welcome to the RTL devShell on ${system}!"

            # Define the shortcuts as functions
            rtl-s() {
              java -jar RtlTester.jar -s "$1"
            }

            rtl-e() {
              java -jar RtlTester.jar -e "$1"
            }

            # Optional: Export them so they are available in subshells
            export -f rtl-s
            export -f rtl-e
          '';
        };
      };
    };
}
