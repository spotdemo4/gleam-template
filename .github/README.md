# gleam template

[![check](https://img.shields.io/github/actions/workflow/status/spotdemo4/gleam-template/check.yaml?branch=main&logo=github&logoColor=%23bac2de&label=check&labelColor=%23313244)](https://github.com/spotdemo4/gleam-template/actions/workflows/check.yaml)
[![vulnerable](https://img.shields.io/github/actions/workflow/status/spotdemo4/gleam-template/vulnerable.yaml?branch=main&logo=github&logoColor=%23bac2de&label=vulnerable&labelColor=%23313244)](https://github.com/spotdemo4/gleam-template/actions/workflows/vulnerable.yaml)

template for starting [gleam](https://gleam.run/) projects

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

### run

```elm
nix run #run
```

### build

```elm
nix build
```

### check

```elm
nix flake check
```

### release

releases are automatically created for [significant](https://www.conventionalcommits.org/en/v1.0.0/#summary) changes

to manually create a version bump:

```elm
bumper action.yaml .github/README.md
```

## use

### download

[releases](https://github.com/spotdemo4/gleam-template/releases/latest)

### docker

```elm
docker run ghcr.io/spotdemo4/gleam-template:0.1.0
```

### action

```yaml
- name: gleam template
  uses: spotdemo4/gleam-template@v0.1.0
```

### nix

```elm
nix run github:spotdemo4/gleam-template
```
