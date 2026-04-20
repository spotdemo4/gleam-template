# gleam template

[![check](https://img.shields.io/github/actions/workflow/status/spotdemo4/gleam-template/check.yaml?branch=main&logo=github&logoColor=%23bac2de&label=check&labelColor=%23313244)](https://github.com/spotdemo4/gleam-template/actions/workflows/check.yaml)
[![vulnerable](https://img.shields.io/github/actions/workflow/status/spotdemo4/gleam-template/vulnerable.yaml?branch=main&logo=github&logoColor=%23bac2de&label=vulnerable&labelColor=%23313244)](https://github.com/spotdemo4/gleam-template/actions/workflows/vulnerable.yaml)
[![nix](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2Fspotdemo4%2Fgleam-template%2Frefs%2Fheads%2Fmain%2Fflake.lock&query=%24.nodes.nixpkgs.original.ref&logo=nixos&logoColor=%23bac2de&label=channel&labelColor=%23313244&color=%234d6fb7)](https://nixos.org/)
[![flakehub](https://img.shields.io/endpoint?url=https://flakehub.com/f/spotdemo4/gleam-template/badge&labelColor=%23313244)](https://flakehub.com/flake/spotdemo4/gleam-template)

template for starting [Gleam](https://gleam.run/) projects

part of [spotdemo4/templates](https://github.com/spotdemo4/templates)

## requirements

- [nix](https://nixos.org/)

## getting started

```elm
nix develop
```

### run

```elm
nix run
```

### format

```elm
nix fmt
```

### check

```elm
nix flake check
```

### build

```elm
nix build
```

### release

```elm
bumper "action.yaml" ".github/README.md"
```

releases are automatically created for [significant](https://www.conventionalcommits.org/en/v1.0.0/#summary) changes

## use

### download

| Architecture | Download                                                                                                                                        |
| ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| amd64        | [gleam-template_0.1.1_amd64.AppImage](https://github.com/spotdemo4/gleam-template/releases/download/v0.1.1/gleam-template_0.1.1_amd64.AppImage) |
| arm64        | [gleam-template_0.1.1_arm64.AppImage](https://github.com/spotdemo4/gleam-template/releases/download/v0.1.1/gleam-template_0.1.1_arm64.AppImage) |
| arm          | [gleam-template_0.1.1_arm.AppImage](https://github.com/spotdemo4/gleam-template/releases/download/v0.1.1/gleam-template_0.1.1_arm.AppImage)     |

### docker

```elm
docker run ghcr.io/spotdemo4/gleam-template:0.1.1
```

### nix

```elm
nix run github:spotdemo4/gleam-template
```

### action

```yaml
- uses: spotdemo4/gleam-template@v0.1.1
```
