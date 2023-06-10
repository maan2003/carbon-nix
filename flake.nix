{
  description = "dev environment for carbon lang";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        llvm = pkgs.llvmPackages_latest;
        clang = pkgs.stdenv.mkDerivation {
          name = "cc-wrapper-bazel";
          buildInputs = [ llvm.clangUseLLVM pkgs.makeWrapper ];
          phases = [ "fixupPhase" ];
          postFixup = ''
            mkdir -p $out/bin
            makeWrapper ${llvm.clangUseLLVM}/bin/clang $out/bin/clang \
              --add-flags "-I${pkgs.zlib.dev}/include \
                           -I${llvm.compiler-rt.dev}/include \
                           -L${llvm.libunwind}/lib \
                           -L${llvm.libcxxabi}/lib \
                           -L${pkgs.zlib}/lib \
                           -L${llvm.libcxx}/lib"
            makeWrapper ${llvm.clangUseLLVM}/bin/clang++ $out/bin/clang++ \
              --add-flags "-I${pkgs.zlib.dev}/include \
                           -I${llvm.compiler-rt.dev}/include \
                           -L${llvm.libunwind}/lib \
                           -L${llvm.libcxxabi}/lib \
                           -L${pkgs.zlib}/lib \
                           -L${llvm.libcxx}/lib"
          '';
        };
      in {
        devShells = {
          default = (pkgs.mkShell.override { stdenv = pkgs.stdenvAdapters.overrideCC llvm.stdenv clang; }) {
            LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [ llvm.libcxxabi pkgs.gcc-unwrapped pkgs.zlib ];
            nativeBuildInputs = with pkgs; [
              clang
              llvm.lld
              llvm.llvm
              llvm.libcxx
              llvm.libcxxabi
              llvm.lldb
              bazel_6
              zlib
              python3 # for scripts
              clang-tools # provides clangd for editor support, your editor should pick this up
              which # for debugging
              pre-commit # pre commit hooks
            ];
          };
        };
      });
}
