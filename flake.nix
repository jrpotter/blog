{
  description = "A very basic flake";

  outputs = { self, nixpkgs }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      ruby = pkgs.ruby;
      gems = pkgs.bundlerEnv {
        name = "pages-env";
        inherit ruby;
        gemdir = self;
      };
    in {
      defaultPackage.x86_64-linux = self.packages.x86_64-linux.jekyll;

      packages.x86_64-linux.jekyll =
        with import nixpkgs { system = "x86_64-linux"; };
        stdenv.mkDerivation {
          name = "jekyll";
          src = self;
          buildInputs = [ gems ];
          installPhase = ''
            mkdir -p $out/{bin,share/jekyll}
            cp -r * $out/share/jekyll
            bin=$out/bin/jekyll
            cat > $bin <<EOF
#!/bin/sh -e
exec ${gems}/bin/jekyll serve --watch
EOF
            chmod +x $bin
          '';
        };

      devShell.x86_64-linux = pkgs.mkShell {
        buildInputs = [
          pkgs.bundix
          pkgs.ruby.devEnv
          self.packages.x86_64-linux.jekyll
        ];
      };
    };
}
