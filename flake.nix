{
  description = "Nix flake packaging the Sherif monorepo linter (Rust)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    crane.url = "github:ipetkov/crane";
    sherif-src = {
      # Pin to the latest release tag; flake.lock will record the exact hash
      url = "github:QuiiBz/sherif/v1.6.1";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, crane, sherif-src, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          craneLib = (crane.mkLib pkgs);
          src = craneLib.cleanCargoSource sherif-src;

          common = {
            pname = "sherif";
            version = "1.6.1";
            inherit src;
          };

          cargoArtifacts = craneLib.buildDepsOnly (common);

          sherif = craneLib.buildPackage (common // {
            inherit cargoArtifacts;
            doCheck = false;
            meta = with pkgs.lib; {
              description = "Opinionated, zero-config linter for JavaScript monorepos";
              homepage = "https://github.com/QuiiBz/sherif";
              license = licenses.mit;
              mainProgram = "sherif";
              platforms = platforms.unix;
            };
          });
        in
        {
          default = sherif;
          sherif = sherif;
        });

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/sherif";
        };
        sherif = {
          type = "app";
          program = "${self.packages.${system}.sherif}/bin/sherif";
        };
      });

      overlays.default = final: prev: {
        sherif = self.packages.${final.system}.sherif;
      };
    };
}
