{
  description = "dev environment for carbon lang";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        llvm = pkgs.llvmPackages_latest;
        # taken from nixpkgs
        clangUseLLVM = let
          release_version = "14.0.6";
          mkExtraBuildCommands0 = cc: ''
            rsrc="$out/resource-root"
            mkdir "$rsrc"
            ln -s "${cc.lib}/lib/clang/${release_version}/include" "$rsrc"
            echo "-resource-dir=$rsrc" >> $out/nix-support/cc-cflags
          '';
          mkExtraBuildCommands = cc:
            mkExtraBuildCommands0 cc + ''
              ln -s "${llvm.compiler-rt.out}/lib" "$rsrc/lib"
              ln -s "${llvm.compiler-rt.out}/share" "$rsrc/share"
            '';
        in (pkgs.wrapCCWith rec {
          cc = llvm.clang-unwrapped;
          libcxx = llvm.libcxx;
          bintools = llvm.bintools;
          extraPackages = [ llvm.libcxxabi llvm.compiler-rt llvm.libunwind ];
          extraBuildCommands = mkExtraBuildCommands cc;
          nixSupport.cc-cflags = [
            "-rtlib=compiler-rt"
            "-Wno-unused-command-line-argument"
            "-B${llvm.compiler-rt}/lib"
            "-lunwind"
            "--unwindlib=libunwind"
            "-I${pkgs.zlib.dev}/include" # include zlib, it is not detected by bazel otherwise
          ];
          nixSupport.cc-ldflags = [ "-L${llvm.libunwind}/lib" ];
        });
      in {
        devShells = {
          default = (pkgs.buildFHSUserEnv {
            name = "carbon-dev";
            targetPkgs = pkgs:
              with pkgs; [
                clangUseLLVM
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
          }).env;
          # does not work yet
          # not-fhs = (pkgs.mkShell.override { stdenv = pkgs.stdenvAdapters.overrideCC pkgs.stdenv clangUseLLVM; }) {
          #   LD_LIBRARY_PATH = lib.makeLibraryPath [ llvm.libcxxabi ];
          #   nativeBuildInputs = with pkgs; [
          #     llvm.libcxx
          #     llvm.libcxxabi
          #     zlib.dev
          #   ];
          #   buildInputs = with pkgs; [
          #     bazel_6
          #     zlib
          #   ];
          # };
        };
      });
}
