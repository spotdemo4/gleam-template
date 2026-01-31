# template

[![check](https://img.shields.io/github/actions/workflow/status/spotdemo4/template/check.yaml?branch=main&logo=github&logoColor=%23bac2de&label=check&labelColor=%23313244)](https://github.com/spotdemo4/template/actions/workflows/check.yaml)
[![vulnerable](https://img.shields.io/github/actions/workflow/status/spotdemo4/template/vulnerable.yaml?branch=main&logo=github&logoColor=%23bac2de&label=vulnerable&labelColor=%23313244)](https://github.com/spotdemo4/template/actions/workflows/vulnerable.yaml)

default template for projects

part of [spotdemo4/templates](https://github.com/spotdemo4/templates)

## requirements

- [nix](https://nixos.org/)
- [direnv](https://direnv.net/) (optional)

## getting started

initialize direnv:

```elm
ln -s .envrc.project .envrc &&
direnv allow
```

or manually enter the development environment:

```elm
nix develop
```

### check

```elm
nix flake check
```

### release

releases are automatically created for [significant](https://www.conventionalcommits.org/en/v1.0.0/#summary) changes

to manually create a version bump:

```elm
bumper
```
