{
  description = "gleam template";

  nixConfig = {
    extra-substituters = [
      "https://nix.trev.zip"
    ];
    extra-trusted-public-keys = [
      "trev:I39N/EsnHkvfmsbx8RUW+ia5dOzojTQNCTzKYij1chU="
    ];
  };

  inputs = {
    systems.url = "github:nix-systems/default";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    trev = {
      url = "github:spotdemo4/nur";
      inputs.systems.follows = "systems";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      trev,
      ...
    }:
    trev.libs.mkFlake (
      system: pkgs: {
        devShells = {
          default = pkgs.mkShell {
            shellHook = pkgs.shellhook.ref;
            packages = with pkgs; [
              # gleam
              gleam
              beam28Packages.erlang
              beam28Packages.rebar3

              # format
              nixfmt
              prettier

              # util
              bumper
              flake-release
            ];
          };

          bump = pkgs.mkShell {
            packages = with pkgs; [
              bumper
            ];
          };

          release = pkgs.mkShell {
            packages = with pkgs; [
              flake-release
            ];
          };

          update = pkgs.mkShell {
            packages = with pkgs; [
              renovate

              # gleam
              gleam
              beam28Packages.erlang
              beam28Packages.rebar3
            ];
          };

          vulnerable = pkgs.mkShell {
            packages = with pkgs; [
              go-over # gleam
              flake-checker # nix
              octoscan # actions
            ];
          };
        };

        apps = pkgs.mkApps {
          default = "gleam run";
          dev = "gleam dev";
        };

        checks = pkgs.mkChecks {
          gleam = {
            src = self.packages.${system}.default;
            script = ''
              gleam check
              gleam format --check
              gleam test
            '';
          };

          actions = {
            root = ./.;
            files = ./.github/workflows;
            packages = with pkgs; [
              action-validator
              octoscan
            ];
            forEach = ''
              action-validator "$file"
              octoscan scan "$file"
            '';
          };

          renovate = {
            root = ./.github;
            files = ./.github/renovate.json;
            packages = with pkgs; [
              renovate
            ];
            script = ''
              renovate-config-validator renovate.json
            '';
          };

          nix = {
            root = ./.;
            filter = file: file.hasExt "nix";
            packages = with pkgs; [
              nixfmt
            ];
            forEach = ''
              nixfmt --check "$file"
            '';
          };

          prettier = {
            root = ./.;
            filter = file: file.hasExt "yaml" || file.hasExt "json" || file.hasExt "md";
            packages = with pkgs; [
              prettier
            ];
            forEach = ''
              prettier --check "$file"
            '';
          };
        };

        formatter = pkgs.treefmt.withConfig {
          configFile = ./treefmt.toml;
          runtimeInputs = with pkgs; [
            gleam
            nixfmt
            prettier
          ];
        };

        packages.default = pkgs.stdenv.mkDerivation (
          final: with pkgs.lib; {
            pname = "gleam-template";
            version = "0.1.2";

            src = fileset.toSource {
              root = ./.;
              fileset = fileset.unions [
                ./gleam.toml
                ./manifest.toml
                ./src
                ./test
              ];
            };

            gleamDeps = pkgs.gleamFetchDeps {
              inherit (final) pname version src;
              hash = "sha256-KqMwVaZveYR+GWV4XIIprmQ1BemkCV8PeCHg/qyf6uM=";
            };

            nativeBuildInputs = with pkgs; [
              gleamErlangHook
            ];

            meta = {
              mainProgram = "template";
              description = "A template for gleam projects";
              license = licenses.mit;
              platforms = platforms.all;
              badPlatforms = [ systems.inspect.platformPatterns.isStatic ];
              homepage = "https://github.com/spotdemo4/gleam-template";
              changelog = "https://github.com/spotdemo4/gleam-template/releases/tag/v${final.version}";
            };
          }
        );

        images.default = pkgs.mkImage {
          src = self.packages.${system}.default;
        };

        appimages.default = pkgs.mkAppImage {
          src = self.packages.${system}.default;
        };

        schemas = trev.schemas;
      }
    );
}
