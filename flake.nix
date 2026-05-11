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
    systems.url = "github:spotdemo4/systems";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    trevpkgs = {
      url = "github:spotdemo4/trevpkgs";
      inputs.systems.follows = "systems";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      trevpkgs,
      ...
    }:
    trevpkgs.libs.mkFlake (
      system: pkgs: {

        # nix develop [#...]
        devShells = {
          default = pkgs.mkShell {
            shellHook = pkgs.shellhook.ref;
            packages = with pkgs; [
              # gleam
              gleam
              erlang
              rebar3

              # lint
              nixd
              nil

              # format
              oxfmt
              nixfmt
              treefmt

              # util
              bumper
              fix-hash
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
              fix-hash # gleamDeps

              # gleam
              gleam
              erlang
              rebar3
            ];
          };

          vulnerable = pkgs.mkShell {
            packages = with pkgs; [
              go-over # gleam
              flake-checker # nix
              zizmor # actions
            ];
          };
        };

        # nix run [#...]
        apps = pkgs.mkApps {
          dev = "gleam dev";
        };

        # nix build [#...]
        packages = {
          default = pkgs.stdenv.mkDerivation (
            final: with pkgs.lib; {
              pname = "gleam-template";
              version = "0.3.0";

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

              checkPhase = ''
                gleam format --check
                gleam check
                gleam test
              '';

              meta = {
                mainProgram = "template";
                description = "A template for Gleam projects";
                license = licenses.mit;
                platforms = platforms.all;
                badPlatforms = [ systems.inspect.platformPatterns.isStatic ];
                homepage = "https://github.com/spotdemo4/gleam-template";
                changelog = "https://github.com/spotdemo4/gleam-template/releases/tag/v${final.version}";
              };
            }
          );
        };

        # nix build #images.[...]
        images = {
          default = pkgs.mkImage {
            src = self.packages.${system}.default;
          };
        };

        # nix build #appimages.[...]
        appimages = {
          default = pkgs.mkAppImage {
            src = self.packages.${system}.default;
          };
        };

        # nix fmt
        formatter = pkgs.treefmt.withConfig {
          configFile = ./treefmt.toml;
          runtimeInputs = with pkgs; [
            gleam
            nixfmt
            oxfmt
          ];
        };

        # nix flake check
        checks = pkgs.mkChecks {
          gleam = self.packages.${system}.default.overrideAttrs {
            dontBuild = true;
            installPhase = ''
              touch $out
            '';
          };

          nix = {
            root = ./.;
            filter = file: file.hasExt "nix";
            packages = with pkgs; [
              nixfmt
            ];
            script = ''
              nixfmt --check "$file"
            '';
          };

          actions = {
            root = ./.github/workflows;
            filter = file: file.hasExt "yaml";
            packages = with pkgs; [
              action-validator
              zizmor
            ];
            script = ''
              action-validator "$file"
              zizmor --offline "$file"
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

          config = {
            root = ./.;
            filter = file: file.hasExt "json" || file.hasExt "yaml" || file.hasExt "toml" || file.hasExt "md";
            packages = with pkgs; [
              oxfmt
            ];
            script = ''
              oxfmt --check
            '';
          };
        };
      }
    );
}
