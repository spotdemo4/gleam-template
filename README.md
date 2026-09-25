# gleam template

[![check](https://trev.zip/template/gleam/actions/workflows/check.yaml/badge.svg?branch=main&logo=forgejo&logoColor=%23bac2de&label=check&labelColor=%23313244)](https://trev.zip/template/gleam/actions?workflow=check.yaml)
[![vulnerable](https://trev.zip/template/gleam/actions/workflows/vulnerable.yaml/badge.svg?branch=main&logo=forgejo&logoColor=%23bac2de&label=vulnerable&labelColor=%23313244)](https://trev.zip/template/gleam/actions?workflow=vulnerable.yaml)
[![nixpkgs](https://img.shields.io/endpoint?url=https%3A%2F%2Fnix-shield.trev.zip%2Fbadge%3Furl%3Dhttps%253A%252F%252Ftrev.zip%252Ftemplate%252Fgleam%252Fraw%252Fbranch%252Fmain%252Fflake.lock%26input%3Dnixpkgs&logoColor=%23bac2de&labelColor=%23313244&color=%235277C3)](https://nixos.org/)
[![gleam](https://img.shields.io/badge/dynamic/toml?url=https%3A%2F%2Ftrev.zip%2Ftemplate%2Fgleam%2Fraw%2Fbranch%2Fmain%2Fgleam.toml&query=%24.gleam&logo=gleam&logoColor=%23bac2de&label=version&labelColor=%23313244&color=%23FFAFF3)](https://gleam.run/)

template for starting [Gleam](https://gleam.run/) projects

part of [spotdemo4/templates](https://github.com/spotdemo4/templates)

## requirements

- [nix](https://nixos.org/)

## getting started

```sh
nix develop
./init.sh "Title" "Description"
```

### run

```sh
gleam run
```

### format

```sh
nix fmt
```

### check

```sh
nix flake check
```

### build

```sh
nix build
```

### release

```sh
bumper
```

releases are automatically created for [significant](https://www.conventionalcommits.org/en/v1.0.0/#summary) changes

## use

### docker

```sh
docker run trev.zip/template/gleam:latest
```

### nix

```sh
nix run git+https://trev.zip/template/gleam.git
```

### download

https://trev.zip/template/gleam/releases
