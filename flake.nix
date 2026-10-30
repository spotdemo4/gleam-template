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
              beamPackages.erlang
              beamPackages.rebar3

              vscode-json-languageserver # json
              yaml-language-server # yaml
              tombi # toml
              oxfmt # format

              # nix
              nixd
              nixfmt

              # util
              treefmt
              bumper
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
              beamPackages.erlang
              beamPackages.rebar3
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

        # nix build [#...]
        packages = {
          default = pkgs.mkGleamPackage (
            final: with pkgs.lib; {
              pname = "gleam-template";
              version = "0.8.1";

              src = fileset.toSource {
                root = ./.;
                fileset = fileset.unions [
                  ./gleam.toml
                  ./manifest.toml
                  ./LICENSE
                  ./README.md
                  ./src
                  ./test
                ];
              };

              doCheck = true;
              checkPhase = ''
                runHook preCheck
                gleam test
                runHook postCheck
              '';

              doInstallCheck = true;
              installCheckPhase = ''
                runHook preInstallCheck
                test "$("$out/bin/${final.meta.mainProgram}")" = "Hello, world!"
                runHook postInstallCheck
              '';

              meta = {
                mainProgram = "gleam_template";
                description = "gleam template";
                license = licenses.mit;
                platforms = platforms.all;
                badPlatforms = [ systems.inspect.platformPatterns.isStatic ];
                homepage = "https://trev.zip/template/gleam";
                downloadPage = "https://trev.zip/template/gleam/releases";
                changelog = "https://trev.zip/template/gleam/releases/tag/v${final.version}";
                sourceProvenance = [ sourceTypes.fromSource ];
                maintainers = [ maintainers.spotdemo4 ];
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

        # nix flake init -t git+https://trev.zip/template/gleam
        templates = {
          default = {
            path = ./.;
            description = "gleam template";
            welcomeText = ''
              # gleam template

              `init.sh` requires a git repository with an `origin` remote:

              ```sh
              git init
              git remote add origin <url>
              bash init.sh "Title" "Description"
              ```
            '';
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
          gleam = self.packages.${system}.default;

          gleam-lint = {
            src = self.packages.${system}.default;
            script = ''
              gleam format --check
              gleam check
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

          actions-gh = {
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

          actions-fj = {
            root = ./.forgejo/workflows;
            filter = file: file.hasExt "yaml";
            packages = with pkgs; [
              forgejo-runner
              zizmor
            ];
            script = ''
              forgejo-runner validate --workflow --path "$file"
              zizmor --offline "$file"
            '';
          };

          renovate-gh = {
            root = ./.github;
            files = ./.github/renovate.jsonc;
            packages = with pkgs; [
              renovate
            ];
            script = ''
              renovate-config-validator renovate.jsonc
            '';
          };

          renovate-fj = {
            root = ./.forgejo;
            files = ./.forgejo/renovate.jsonc;
            packages = with pkgs; [
              renovate
            ];
            script = ''
              renovate-config-validator renovate.jsonc
            '';
          };

          config = {
            root = ./.;
            filter =
              file:
              file.hasExt "json"
              || file.hasExt "jsonc"
              || file.hasExt "yaml"
              || file.hasExt "toml"
              || file.hasExt "md";
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
