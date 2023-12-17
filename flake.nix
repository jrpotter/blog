{
  description = "My personal blog.";

  inputs = {
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        gems = pkgs.bundlerEnv {
          name = "blog-gems";
          gemdir = ./.;
          ruby = pkgs.ruby_3_2;
        };
      in
      {
        packages = {
          app = pkgs.stdenv.mkDerivation {
            name = "blog";
            buildInputs = [gems gems.wrappedRuby];
            src = ./.;
            version = "0.1.0";
            installPhase = "jekyll b -d $out";
          };

          default = self.packages.${system}.app;
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            bundix
            gems
            gems.wrappedRuby
          ];
        };
      }
    );
}
