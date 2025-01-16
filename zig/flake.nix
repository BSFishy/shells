{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
  inputs.flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";

  outputs =
    { self, nixpkgs, ... }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
      llvm = pkgs.llvmPackages_19;
    in
    {
      devShell.x86_64-linux = pkgs.mkShell {
        buildInputs = [
          pkgs.stdenv.cc
          pkgs.cmake

          pkgs.libxml2
          pkgs.zlib

          llvm.llvm
          llvm.libclang
          llvm.lld
        ];
      };

      packages.x86_64-linux = rec {
        zig = pkgs.stdenv.mkDerivation {
          pname = "zig";
          version = "dev";

          src = ./.;
          nativeBuildInputs = [
            pkgs.stdenv.cc
            pkgs.cmake

            pkgs.libxml2
            pkgs.zlib

            llvm.llvm
            llvm.libclang
            llvm.lld
          ];

          cmakeFlags = [
            # file RPATH_CHANGE could not write new RPATH
            # (lib.cmakeBool "CMAKE_SKIP_BUILD_RPATH" true)
            # ensure determinism in the compiler build
            # (lib.cmakeFeature "ZIG_TARGET_MCPU" "baseline")
            (pkgs.lib.cmakeFeature "CMAKE_BUILD_TYPE" "Release")
            # always link against static build of LLVM
            # (lib.cmakeBool "ZIG_STATIC_LLVM" true)
          ];

          # configurePhase = ''
          #   cmake -DCMAKE_BUILD_TYPE=Release $SOURCE_ROOT
          # '';
          # buildPhase = ''
          #   make install
          # '';
          # installPhase = ''
          #   cmake --install build
          # '';
        };
      };

      apps.x86_64-linux = {
        zig = {
          type = "app";
          program = "${self.packages.x86_64-linux.zig}/bin/zig";
        };
      };
    };
}
