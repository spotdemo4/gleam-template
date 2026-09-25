# contributing

## requirements

- [nix](https://nixos.org/)

## getting started

```sh
nix develop
```

with [direnv](https://direnv.net/):

```sh
ln -s .envrc.project .envrc
direnv allow
```

### run

```sh
nix run
```

with [gleam](https://gleam.run/):

```sh
gleam run
```

### format

```sh
nix fmt
```

with [gleam](https://gleam.run/):

```sh
gleam format
```

### check

```sh
nix flake check
```

with [gleam](https://gleam.run/):

```sh
gleam check
gleam test
```

### build

```sh
nix build
```

with [gleam](https://gleam.run/):

```sh
gleam build
```

### release

with [bumper](https://trev.zip/llc/bumper):

```sh
bumper
```

releases are automatically created for [significant](https://www.conventionalcommits.org/en/v1.0.0/#summary) changes
