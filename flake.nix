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
            fileset = ./.github/workflows;
            deps = with pkgs; [
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
            fileset = ./.github/renovate.json;
            deps = with pkgs; [
              renovate
            ];
            script = ''
              renovate-config-validator renovate.json
            '';
          };

          nix = {
            root = ./.;
            filter = file: file.hasExt "nix";
            deps = with pkgs; [
              nixfmt
            ];
            forEach = ''
              nixfmt --check "$file"
            '';
          };

          prettier = {
            root = ./.;
            filter = file: file.hasExt "yaml" || file.hasExt "json" || file.hasExt "md";
            deps = with pkgs; [
              prettier
            ];
            forEach = ''
              prettier --check "$file"
            '';
          };
        };

        apps = pkgs.mkApps {
          run = "gleam run";
          dev = "gleam dev";
        };

        packages = {
          default = pkgs.buildGleamApplication (finalAttrs: {
            pname = "gleam-template";
            version = "0.1.0";

            src = pkgs.lib.fileset.toSource {
              root = ./.;
              fileset = pkgs.lib.fileset.unions [
                ./gleam.toml
                ./manifest.toml
                ./src
                ./test
              ];
            };

            meta = {
              mainProgram = "template";
              description = "A template for gleam projects.";
              license = pkgs.lib.licenses.mit;
              platforms = pkgs.lib.platforms.all;
              homepage = "https://github.com/spotdemo4/gleam-template";
              changelog = "https://github.com/spotdemo4/gleam-template/releases/tag/v${finalAttrs.version}";
            };
          });
        };

        images = {
          default = pkgs.mkImage self.packages.${system}.default {
            contents = with pkgs; [ dockerTools.caCertificates ];
          };
        };

        formatter = pkgs.nixfmt-tree;
        schemas = trev.schemas;
      }
    );
}
