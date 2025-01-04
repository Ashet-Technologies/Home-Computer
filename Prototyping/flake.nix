{
  description = "Prototyping Environment for Ashet Home Computer";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
    zig.url = "github:mitchellh/zig-overlay";

    # Used for shell.nix
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  } @ inputs: let
    overlays = [
      # Other overlays
      (final: prev: {
        zigpkgs = inputs.zig.packages.${prev.system};
      })
    ];

    # Our supported systems are the same supported systems as the Zig binaries
    systems = builtins.attrNames inputs.zig.packages;
  in
    flake-utils.lib.eachSystem systems (
      system: let
        pkgs = import nixpkgs {inherit overlays system;};
      in rec {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [
            pkgs.cmake
            pkgs.zigpkgs."0.13.0"
            pkgs.openocd
            pkgs.openocd-rp2040
            pkgs.gdb
            pkgs.libusb1
            pkgs.ninja
            pkgs.gcc-arm-embedded
            pkgs.picocom
            pkgs.flex
            pkgs.bison
          ];
          shellHook = ''
              export PATH="$PWD/prefix/bin:$PATH"
          '';
        };
      }
    );
}
