---
name: fix-vulnerable
description: Fixes failures reported by the vulnerable workflow, which runs go_over, flake-checker and zizmor. Use when the vulnerable workflow fails, or when asked about a Hex advisory, a retired Gleam package, an outdated nixpkgs input or a zizmor finding.
---

# Fix Vulnerable

The `vulnerable` workflow runs weekly in each forge directory (`.github`, `.gitea`, `.forgejo`) that exists, with a job for each tool. Read the failed job's log to find which tool failed and why, then reproduce it locally in the `vulnerable` dev shell:

```sh
nix develop .#vulnerable -c go_over
nix develop .#vulnerable -c flake-checker -f
nix develop .#vulnerable -c zizmor .github/workflows
```

## go_over

go_over checks the packages in `manifest.toml` against the Elixir and Erlang security advisories and Hex's retired packages, and fails on any warning. Add `--format detailed` to see each advisory's ID, severity and description. Advisory data is cached for six hours, so add `--force` to check again right after a fix is published.

Renovate opens automerging fix PRs for vulnerable direct dependencies, so check for an open Renovate PR first. A failure without one is usually a transitive dependency, which an open lock file maintenance PR may already update.

1. Update the package within the requirements in `gleam.toml` with `gleam update <package>`, which rewrites `manifest.toml`. Run `gleam` in the default dev shell, for example `nix develop -c gleam update <package>`.
2. If a dependent's requirement rules out the patched version, find the direct dependency that pulls the package in with `gleam deps tree --invert <package>`. Update that one, raising its requirement in `gleam.toml` if needed.
3. For a retired package, update to a version that isn't retired, or replace the package.
4. Only when no patched version exists, or the vulnerable code is unreachable, ignore the advisory by ID in the `[go-over.ignore]` table of `gleam.toml` with a comment explaining why, and tell the user:

   ```toml
   [go-over.ignore]
   ids = [
     "GHSA-0000-0000-0000", # reason
   ]
   ```

   Ignoring by `packages`, `severity` or `indirect` hides every future finding for them, so avoid those.

## flake-checker

flake-checker fails when a nixpkgs input is outdated (over 30 days old), not owned by `NixOS`, or tracks an unsupported branch. Renovate only updates Nix inputs during its weekly lock file maintenance, which automerges.

1. Check for an open Renovate lock file maintenance PR. If one exists, its checks are probably failing, so fix the failure on that PR's branch instead of opening a competing one.
2. Otherwise run `nix flake update`, then fix anything the update breaks.
3. For an owner or branch failure, change the input's URL in `flake.nix` to a supported `NixOS/nixpkgs` branch.

## zizmor

zizmor audits the workflows for security issues. CI runs its online audits with a GitHub token. Locally, set `GH_TOKEN` to enable them, for example with `GH_TOKEN=$(gh auth token)`, or they're skipped.

1. Fix the finding in every forge directory that has the workflow, not only the one that failed. The forges' workflows differ: GitHub and Gitea set `permissions`, while Forgejo doesn't support them and uses `enable-openid-connect`. Adapt the fix to each forge rather than copying it.
2. Pinned action updates (`unpinned-uses`, known vulnerable versions) are Renovate's job, so check for an open Renovate PR first.
3. Only when a finding doesn't apply to a forge, ignore it with an inline `# zizmor: ignore[<audit>]` comment on the flagged line, as the Forgejo workflows do for `excessive-permissions`.

## Finish

Run `nix flake check`, and confirm each tool that failed now passes locally.
