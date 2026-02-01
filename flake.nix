{
  description = "gleam template";

  nixConfig = {
    extra-substituters = [
      "https://cache.trev.zip/nur"
    ];
    extra-trusted-public-keys = [
      "nur:70xGHUW1+1b8FqBchldaunN//pZNVo6FKuPL4U/n844="
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
      nixpkgs,
      trev,
      ...
    }:
    trev.libs.mkFlake (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            trev.overlays.packages
            trev.overlays.libs
          ];
        };
        fs = pkgs.lib.fileset;
      in
      rec {
        devShells = {
          default = pkgs.mkShell {
            name = "dev";
            shellHook = pkgs.shellhook.ref;
            packages = with pkgs; [
              gleam
              beam28Packages.erlang
              beam28Packages.rebar3

              # formatters
              nixfmt
              prettier

              # util
              bumper
              flake-release
            ];
          };

          bump = pkgs.mkShell {
            name = "bump";
            packages = with pkgs; [
              bumper
            ];
          };

          release = pkgs.mkShell {
            name = "release";
            packages = with pkgs; [
              flake-release
            ];
          };

          update = pkgs.mkShell {
            name = "update";
            packages = with pkgs; [
              renovate
            ];
          };

          vulnerable = pkgs.mkShell {
            name = "vulnerable";
            packages = with pkgs; [
              # gleam
              go-over

              # nix
              flake-checker

              # actions
              octoscan
            ];
          };
        };

        checks = pkgs.lib.mkChecks {
          gleam = {
            src = packages.default;
            script = ''
              gleam check
              gleam format --check
              gleam test
            '';
          };

          actions = {
            src = fs.toSource {
              root = ./.;
              fileset = ./.github/workflows;
            };
            deps = with pkgs; [
              action-validator
              octoscan
            ];
            script = ''
              action-validator **/*.yaml
              octoscan scan .
            '';
          };

          renovate = {
            src = fs.toSource {
              root = ./.github;
              fileset = ./.github/renovate.json;
            };
            deps = with pkgs; [
              renovate
            ];
            script = ''
              renovate-config-validator renovate.json
            '';
          };

          nix = {
            src = fs.toSource {
              root = ./.;
              fileset = fs.fileFilter (file: file.hasExt "nix") ./.;
            };
            deps = with pkgs; [
              nixfmt-tree
            ];
            script = ''
              treefmt --ci
            '';
          };

          prettier = {
            src = fs.toSource {
              root = ./.;
              fileset = fs.fileFilter (file: file.hasExt "yaml" || file.hasExt "json" || file.hasExt "md") ./.;
            };
            deps = with pkgs; [
              prettier
            ];
            script = ''
              prettier --check .
            '';
          };
        };

        apps = pkgs.lib.mkApps {
          run.script = "gleam run";
          dev.script = "gleam dev";
        };

        packages = with pkgs.lib; rec {
          default = gleam.build rec {
            pname = "gleam-template";
            version = "0.0.1";

            src = fs.toSource {
              root = ./.;
              fileset = fs.unions [
                ./gleam.toml
                ./manifest.toml
                (fs.fileFilter (file: file.hasExt "gleam") ./.)
              ];
            };

            target = "erlang";
            erlangPackage = pkgs.beam28Packages.erlang;
            rebar3Package = pkgs.beam28Packages.rebar3;

            meta = {
              description = "gleam template";
              mainProgram = "template";
              homepage = "https://github.com/spotdemo4/gleam-template";
              changelog = "https://github.com/spotdemo4/gleam-template/releases/tag/v${version}";
              license = licenses.mit;
              platforms = platforms.all;
            };
          };

          image = makeOverridable pkgs.dockerTools.buildLayeredImage {
            name = default.pname;
            tag = default.version;

            contents = with pkgs; [
              dockerTools.caCertificates
            ];

            created = "now";
            meta = default.meta;

            config = {
              Cmd = [ "${meta.getExe default}" ];
              Labels = {
                "org.opencontainers.image.title" = default.pname;
                "org.opencontainers.image.description" = default.meta.description;
                "org.opencontainers.image.version" = default.version;
                "org.opencontainers.image.source" = default.meta.homepage;
                "org.opencontainers.image.licenses" = default.meta.license.spdxId;
              };
            };
          };
        };

        formatter = pkgs.nixfmt-tree;
      }
    );
}
