{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-21.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        ruby = pkgs.ruby_2_7;
        gems = pkgs.bundlerEnv {
          name = "pages-env";
          inherit ruby;
          gemdir = self;
        };
      in {
        defaultPackage = self.packages.${system}.jekyll;

        packages.jekyll =
          with import nixpkgs { inherit system; };
          stdenv.mkDerivation {
            name = "jekyll";
            dontUnpack = true;
            buildInputs = [ gems ];
            installPhase = ''
              mkdir -p $out/bin
              bin=$out/bin/jekyll
              cat > $bin <<EOF
  #!/bin/sh -e
  ${gems}/bin/jekyll serve --watch
  EOF
              chmod +x $bin
            '';
          };

        devShell = pkgs.mkShell {
          buildInputs = [
            pkgs.bundix
            pkgs.bundler
            self.packages.${system}.jekyll
          ];
        };
      });
}
