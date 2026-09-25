# gleam template

[![check](https://trev.zip/template/gleam/actions/workflows/check.yaml/badge.svg?branch=main&logo=forgejo&logoColor=%23bac2de&label=check&labelColor=%23313244)](https://trev.zip/template/gleam/actions?workflow=check.yaml)
[![vulnerable](https://trev.zip/template/gleam/actions/workflows/vulnerable.yaml/badge.svg?branch=main&logo=forgejo&logoColor=%23bac2de&label=vulnerable&labelColor=%23313244)](https://trev.zip/template/gleam/actions?workflow=vulnerable.yaml)
[![nixpkgs](https://nix-shield.trev.zip/?url=https://trev.zip/template/gleam/raw/branch/main/flake.lock&input=nixpkgs&logoColor=%23bac2de&labelColor=%23313244&color=%235277C3)](https://nixos.org/)
[![gleam](https://img.shields.io/badge/dynamic/toml?url=https%3A%2F%2Ftrev.zip%2Ftemplate%2Fgleam%2Fraw%2Fbranch%2Fmain%2Fgleam.toml&query=%24.gleam&logo=gleam&logoColor=%23bac2de&label=version&labelColor=%23313244&color=%23FFAFF3)](https://gleam.run/)

template for starting [Gleam](https://gleam.run/) projects

to initialize a new project, run:

```sh
./init.sh "Title" "Description"
```

part of [spotdemo4/templates](https://github.com/spotdemo4/templates)

## using

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

## contributing

see [CONTRIBUTING.md](CONTRIBUTING.md) for requirements and getting started
