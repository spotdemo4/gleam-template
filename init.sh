#!/usr/bin/env bash
# The script often single-quotes text containing $ for printf, sed and Nix
# shellcheck disable=SC2016

# Initializes a project from this template. init.test.sh tests it.

set -euo pipefail
# Functions that print their result run in command substitutions
shopt -s inherit_errexit

old_slug=gleam-template
old_package=gleam_template
old_description='gleam template'
old_url=https://trev.zip/template/gleam
old_maintainer='maintainers.spotdemo4'
old_maintainer_email=me@trev.xyz
version=0.0.1

die() {
  printf '%s\n' "$1" >&2
  exit 1
}

# Sets remote_host, remote_repo_path and remote_web_url from a Git remote URL.
# The label names the URL in error messages.
parse_remote() {
  local label=$1 url=$2 scheme=https remote_path authority
  if [[ $url == *'?'* || $url == *'#'* ]]; then
    die "$label cannot contain a query string or fragment."
  fi
  case $url in
    http://* | https://*)
      scheme=${url%%://*}
      remote_path=${url#*://}
      authority=${remote_path%%/*}
      remote_host=${authority##*@}
      remote_repo_path=${remote_path#*/}
      ;;
    git@*:*)
      remote_host=${url#git@}
      remote_host=${remote_host%%:*}
      remote_repo_path=${url#*:}
      ;;
    ssh://*)
      remote_path=${url#ssh://}
      authority=${remote_path%%/*}
      remote_host=${authority##*@}
      remote_host=${remote_host%%:*}
      remote_repo_path=${remote_path#*/}
      ;;
    *)
      die "Unsupported ${label,}."
      ;;
  esac
  remote_repo_path=${remote_repo_path#/}
  remote_repo_path=${remote_repo_path%.git}
  if [[ $remote_repo_path != */* ]]; then
    die "$label must identify an owner and repository."
  fi
  if [[ ! $remote_host =~ ^[A-Za-z0-9.-]+(:[0-9]+)?$ || ! $remote_repo_path =~ ^[A-Za-z0-9._/-]+$ ]]; then
    die "$label contains unsupported host or path characters."
  fi
  remote_web_url="$scheme://$remote_host/$remote_repo_path"
}

# Prints the package name for a project title.
slugify() {
  local slug
  slug=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')
  if [[ ! $slug =~ ^[a-z][a-z0-9-]*$ ]]; then
    die 'Title must produce a package name beginning with a letter.'
  fi
  printf '%s\n' "$slug"
}

# Prints the Gleam package name for a slug. Gleam package names can't be
# reserved words or the names of Erlang modules.
gleam_package() {
  local package=${1//-/_}
  case $package in
    as | assert | auto | case | const | delegate | derive | echo | else | fn | if | implement | import | let | macro | opaque | panic | pub | test | todo | type | use | \
      receive | bnot | div | rem | band | bor | bxor | bsl | bsr | not | and | or | xor | orelse | andalso | when | end | fun | try | catch | after | begin | query | cond | of | maybe | \
      gleam | array | base64 | beam_lib | binary | c | calendar | dets | dict | digraph | digraph_utils | epp | erl_anno | erl_eval | erl_expand_records | erl_id_trans | erl_internal | erl_lint | erl_parse | erl_pp | erl_scan | erl_tar | ets | file_sorter | filelib | filename | gb_sets | gb_trees | \
      gen_event | gen_fsm | gen_server | gen_statem | io | io_lib | lists | log_mf_h | maps | math | ms_transform | orddict | ordsets | pool | proc_lib | proplists | qlc | queue | rand | random | re | sets | shell | shell_default | shell_docs | slave | sofs | string | supervisor | supervisor_bridge | \
      sys | timer | unicode | uri_string | user_default | win32reg | zip)
      die 'Title must produce a Gleam package name that is not reserved.'
      ;;
  esac
  printf '%s\n' "$package"
}

# Prints a value escaped for a double-quoted Nix string.
nix_string() {
  local value=$1
  # shellcheck disable=SC1003
  value=${value//'\'/'\\'}
  value=${value//'"'/'\"'}
  value=${value//'${'/'\${'}
  printf '%s\n' "$value"
}

# Replaces every occurrence of old with new in the given files.
replace_literal() {
  local old=$1 new=$2 file content
  shift 2
  for file in "$@"; do
    content=$(<"$file")
    printf '%s\n' "${content//"$old"/"$new"}" >"$file"
  done
}

remove_checks() {
  local key
  for key in "$@"; do
    sed -i "/^          $key = {$/,/^          };$/d" flake.nix
  done
}

# Prints the template commit this project started from. Repositories created
# with "use this template" have a new commit, but its tree matches the
# template's.
find_template_commit() {
  local commit tree
  local -A template_trees=()
  if ! GIT_TERMINAL_PROMPT=0 git fetch --quiet --no-tags "$old_url" main 2>/dev/null; then
    return
  fi
  while read -r commit tree; do
    if [[ ! -v template_trees[$tree] ]]; then
      template_trees[$tree]=$commit
    fi
  done < <(git log --format='%H %T' FETCH_HEAD)
  while read -r tree; do
    # nix flake init drops the executable bit from init.sh
    tree=$(git ls-tree -z "$tree" | sed -z 's/^100644\( blob [0-9a-f]*\tinit\.sh\)$/100755\1/' | git mktree -z --missing)
    if [[ -v template_trees[$tree] ]]; then
      printf '%s\n' "${template_trees[$tree]}"
      return
    fi
  done < <(git log --format='%T' HEAD)
}

# Checks that the initializer runs from the root of a regular Git repository
# with a Git user.
check_repository() {
  root=$(git rev-parse --show-toplevel 2>/dev/null) || die 'The initializer must be run from a Git repository.'
  root=$(realpath "$root")
  script_path=$(realpath "$0")
  if [[ $(pwd -P) != "$root" || $script_path != "$root/init.sh" ]]; then
    die 'Run ./init.sh from the repository root.'
  fi
  if [[ ! -d $root/.git || -L $root/.git ]]; then
    die 'Linked worktrees and repositories with a .git file are not supported.'
  fi
  if [[ $(git config --bool core.sparseCheckout || true) == true ]]; then
    die 'Sparse checkouts are not supported.'
  fi
  git_name=$(git config user.name || true)
  git_email=$(git config user.email || true)
  if [[ -z $git_name || -z $git_email ]]; then
    die 'Configure Git user.name and user.email before running the initializer.'
  fi
  if [[ $git_name =~ [[:cntrl:]] || $git_email =~ [[:cntrl:]] ]]; then
    die 'Git user.name and user.email cannot contain control characters.'
  fi
}

# Checks the title and description, and reads the project's location from the
# origin remote.
check_project() {
  if [[ $title =~ [[:cntrl:]] || $description =~ [[:cntrl:]] ]]; then
    die 'Title and description cannot contain control characters.'
  fi
  # Gleam writes the description into the Erlang .app file without escaping it
  if [[ $description == *[\"\\]* ]]; then
    die 'Description cannot contain double quotes or backslashes.'
  fi
  slug=$(slugify "$title")
  package=$(gleam_package "$slug")

  remote=$(git remote get-url origin 2>/dev/null) || die 'Unable to read the origin remote.'
  parse_remote 'Origin URL' "$remote"
  host=$remote_host
  repo_path=$remote_repo_path
  web_url=$remote_web_url
  provider_host=${host%%:*}
  owner=${repo_path%%/*}
  repo=${repo_path##*/}
  if [[ ${provider_host,,} == github.com ]]; then
    is_github=true
  else
    is_github=false
  fi
  mapfile -t remote_urls < <(git config --get-all remote.origin.url)
  mapfile -t push_urls < <(git config --get-all remote.origin.pushurl || true)
}

# Checks that the worktree is clean and records the tracked files.
check_worktree() {
  local worktree_status
  # Repositories set up with nix flake init have no commits yet. Commit the
  # template so a failed run can be rolled back; the new repository replaces it.
  if ! git rev-parse --verify --quiet HEAD >/dev/null; then
    git add -A
    git_as_user git -c commit.gpgsign=false -c core.hooksPath=/dev/null commit --quiet --message 'chore: add template'
  fi

  worktree_status=$(git status --porcelain=v1 --untracked-files=all) || die 'Unable to inspect the Git worktree.'
  if [[ -n $worktree_status ]]; then
    die 'Commit or discard all existing worktree changes before running the initializer.'
  fi
  mapfile -d '' -t tracked_files < <(git ls-files -z)
  wait "$!" || die 'Unable to inspect tracked files.'
}

# Runs a Git command as the Git user, whatever the environment sets.
git_as_user() {
  env \
    GIT_AUTHOR_NAME="$git_name" \
    GIT_AUTHOR_EMAIL="$git_email" \
    GIT_COMMITTER_NAME="$git_name" \
    GIT_COMMITTER_EMAIL="$git_email" \
    "$@"
}

# Creates the repository that replaces .git once the project is initialized,
# and restores the template if initialization fails.
start_new_repository() {
  local repo_name=${root##*/}
  new_git_dir="${root%/*}/.${repo_name}.git-new.$$"
  old_git_dir="${root%/*}/.${repo_name}.git-old.$$"
  if [[ -e $new_git_dir || -e $old_git_dir ]]; then
    die 'Temporary Git directory already exists.'
  fi
  git init --bare --quiet --initial-branch=main "$new_git_dir"
  new_git=(git --git-dir="$new_git_dir" --work-tree="$root")
  swap_started=false
  changes_started=false
  trap cleanup EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
  trap 'exit 129' HUP
}

cleanup() {
  local status=$?
  trap - EXIT INT TERM HUP
  if $swap_started && [[ -e $old_git_dir ]]; then
    rm -rf .git
    mv "$old_git_dir" .git
    if [[ ! -e $script_path ]]; then
      git restore -- init.sh || true
    fi
  elif $changes_started; then
    git restore --source=HEAD --staged --worktree -- . || true
    git clean -fdq || true
  fi
  rm -rf "$new_git_dir"
  exit "$status"
}

# Removes the template's own files and replaces its metadata with the project's.
apply_metadata() {
  local year library_field=
  year=$(date +%Y)

  rm init.test.sh template.schema.json
  sed -i '/^        # nix flake init /,/^        };$/d' flake.nix
  remove_checks init
  sed -i '/^# Linguist: exclude template /,/^$/d' .gitattributes

  if [[ -n $template_commit ]]; then
    if $is_library; then
      library_field=', "library": true'
    fi
    printf '{ "$schema": "%s", "url": "%s", "commit": "%s"%s }\n' \
      "$old_url/raw/branch/main/template.schema.json" "$old_url" "$template_commit" "$library_field" >.template.json
  else
    printf 'Warning: unable to find the template commit; .template.json was not created.\n' >&2
  fi

  replace_literal "$old_slug" "$slug" flake.nix
  replace_literal "$old_package" "$package" gleam.toml flake.nix
  sed -i -E "1,/^\[/s@^(version = \")[^\"]*@\1$version@" gleam.toml
  sed -i -E "/^[[:space:]]*pname = \"$slug\";$/,/^[[:space:]]*version = /s@^([[:space:]]*version = \")[^\"]*@\1$version@" flake.nix
  if [[ -f src/$old_package.gleam && $old_package != "$package" ]]; then
    mv "src/$old_package.gleam" "src/$package.gleam"
  fi
  if [[ -f test/${old_package}_test.gleam && $old_package != "$package" ]]; then
    mv "test/${old_package}_test.gleam" "test/${package}_test.gleam"
  fi
  replace_literal "$old_description" "$(nix_string "$description")" flake.nix
  replace_literal "$old_url" "$web_url" flake.nix
  replace_literal "$old_description" "$description" gleam.toml
  if ! $is_github; then
    replace_literal 'type = "github"' "type = \"forgejo\""$'\n'"host = \"${web_url%/"$repo_path"}\"" gleam.toml
  fi
  replace_literal 'user = "template"' "user = \"$owner\"" gleam.toml
  replace_literal 'repo = "gleam"' "repo = \"$repo\"" gleam.toml
  replace_literal 'Copyright (c) 2026 trev' "Copyright (c) $year $git_name" LICENSE
  # Only the template's author has a nixpkgs maintainer entry.
  if [[ ${git_email,,} != "$old_maintainer_email" ]]; then
    replace_literal "[ $old_maintainer ]" \
      "[ { name = \"$(nix_string "$git_name")\"; email = \"$(nix_string "$git_email")\"; } ]" flake.nix
  fi
}

# Replaces the program and its dependencies with a library module.
make_library() {
  local workflow
  cat >"src/$package.gleam" <<'EOF'
//// Says hello.

/// Returns a greeting for `name`.
pub fn hello(name: String) -> String {
  "Hello, " <> name <> "!"
}
EOF
  cat >"test/${package}_test.gleam" <<EOF
import gleeunit
import $package

pub fn main() -> Nil {
  gleeunit.main()
}

// gleeunit test functions end in \`_test\`
pub fn hello_test() {
  assert $package.hello("world") == "Hello, world!"
}
EOF
  # The standard library stays locked in manifest.toml as a dependency of gleeunit
  sed -i '/^gleam_stdlib = /d' gleam.toml
  sed -i '/^gleam_stdlib = { version = /d' manifest.toml

  # There's no program to run or put in an image.
  sed -i "/^              doInstallCheck = true;\$/,/^              '';\$/d" flake.nix
  sed -i -E '/^                (mainProgram|downloadPage) = /d' flake.nix
  sed -i -E '/^        # nix build #(app)?images/,/^        };$/d' flake.nix
  sed -i '/^### run$/,/^### format$/{/^### format$/!d}' CONTRIBUTING.md

  # flake-release can't publish to Hex, so the release only archives the package.
  for workflow in .github/workflows/release.yaml .forgejo/workflows/release.yaml; do
    if [[ -f $workflow ]]; then
      sed -i -E '/^            (images|appimages)\.x86_64-linux\.default\./d' "$workflow"
    fi
  done
  if [[ -f .github/workflows/release.yaml ]]; then
    sed -i '/^      packages: write$/d' .github/workflows/release.yaml
  fi
  if [[ -f .forgejo/workflows/release.yaml ]]; then
    sed -i '/^          CONTAINER_REGISTRY_PASSWORD: /d' .forgejo/workflows/release.yaml
  fi
}

# Replaces the README's title, badges and description, and points its usage
# instructions at the project.
write_readme() {
  local raw_url check_badge vulnerable_badge encoded_lock_url nixpkgs_badge language_badge
  local image readme_sections
  if $is_github; then
    raw_url="https://raw.githubusercontent.com/${repo_path}/refs/heads/main"
    check_badge="[![check](${web_url}/actions/workflows/check.yaml/badge.svg?branch=main)](${web_url}/actions/workflows/check.yaml)"
    vulnerable_badge="[![vulnerable](${web_url}/actions/workflows/vulnerable.yaml/badge.svg?branch=main)](${web_url}/actions/workflows/vulnerable.yaml)"
  else
    raw_url="${web_url}/raw/branch/main"
    check_badge="[![check](${web_url}/actions/workflows/check.yaml/badge.svg?branch=main&logo=forgejo&logoColor=%23bac2de&label=check&labelColor=%23313244)](${web_url}/actions?workflow=check.yaml)"
    vulnerable_badge="[![vulnerable](${web_url}/actions/workflows/vulnerable.yaml/badge.svg?branch=main&logo=forgejo&logoColor=%23bac2de&label=vulnerable&labelColor=%23313244)](${web_url}/actions?workflow=vulnerable.yaml)"
  fi

  # The validated raw URL only needs colons and slashes double-encoded for Shields.
  encoded_lock_url="${raw_url}/flake.lock"
  encoded_lock_url=${encoded_lock_url//:/%253A}
  encoded_lock_url=${encoded_lock_url//\//%252F}
  nixpkgs_badge="[![nixpkgs](https://img.shields.io/endpoint?url=https%3A%2F%2Fnix-shield.trev.zip%2Fbadge%3Furl%3D${encoded_lock_url}%26input%3Dnixpkgs&logoColor=%23bac2de&labelColor=%23313244&color=%235277C3)](https://nixos.org/)"
  # The badge shows the minimum Gleam version from gleam.toml
  language_badge="[![gleam](https://img.shields.io/badge/dynamic/toml?url=${raw_url}/gleam.toml&query=%24.gleam&logo=gleam&logoColor=%23bac2de&label=version&labelColor=%23313244&color=%23FFAFF3)](https://gleam.run/)"

  if $is_library; then
    readme_sections=$(sed -n '/^## contributing$/,$p' README.md)
    printf -v readme_sections '## using\n\n```toml\n# gleam.toml\n[dependencies]\n%s = { git = "%s.git", ref = "main" }\n```\n\n%s' \
      "$package" "$web_url" "$readme_sections"
  else
    if $is_github; then
      image="ghcr.io/${repo_path,,}:latest"
    else
      image="$host/${repo_path,,}:latest"
    fi
    readme_sections=$(sed -n '/^## using$/,$p' README.md)
    readme_sections=${readme_sections//"$old_url"/"$web_url"}
    readme_sections=${readme_sections//trev.zip\/template\/gleam:latest/"$image"}
  fi

  {
    printf '# %s\n\n' "$title"
    printf '%s\n%s\n%s\n%s\n\n' "$check_badge" "$vulnerable_badge" "$nixpkgs_badge" "$language_badge"
    printf '%s\n\n%s\n' "$description" "$readme_sections"
  } >README.md
}

# Sets secondary_remote, secondary_repo_path and secondary_web_url from the URL
# of the project's repository on the other provider.
read_secondary_repository() {
  local provider=$1 secondary_provider_host
  read -r -p "$provider repository URL: " secondary_remote
  parse_remote 'Repository URL' "$secondary_remote"
  secondary_repo_path=$remote_repo_path
  secondary_web_url=$remote_web_url
  secondary_provider_host=${remote_host%%:*}
  if [[ $provider == GitHub && ${secondary_provider_host,,} != github.com ]]; then
    die 'GitHub repository URL must use github.com.'
  fi
  if [[ $provider == Forgejo && ${secondary_provider_host,,} == github.com ]]; then
    die 'Forgejo repository URL cannot use github.com.'
  fi
}

# Points the GitHub and Forgejo configuration at the project's repositories, or
# removes it.
configure_providers() {
  local reply
  if [[ ! -d .github ]]; then
    remove_checks actions-gh renovate-gh
  fi
  if [[ ! -d .forgejo ]]; then
    remove_checks actions-fj renovate-fj
  fi

  if $is_github; then
    if [[ -f .github/renovate.jsonc ]]; then
      replace_literal "spotdemo4/$old_slug" "$repo_path" .github/renovate.jsonc
    fi
    if [[ -d .forgejo ]]; then
      read -r -p 'GitHub origin detected. Delete .forgejo? [y/N] ' reply || reply=
      if [[ $reply =~ ^[Yy]$ ]]; then
        rm -rf .forgejo
        remove_checks actions-fj renovate-fj
      else
        read_secondary_repository Forgejo
        "${new_git[@]}" remote add forgejo "$secondary_remote"
        replace_literal 'template/gleam' "$secondary_repo_path" .forgejo/renovate.jsonc
        replace_literal 'https://trev.zip/api/v1' "${secondary_web_url%/"$secondary_repo_path"}/api/v1" .forgejo/renovate.jsonc
      fi
    fi
  else
    if [[ -f .forgejo/renovate.jsonc ]]; then
      replace_literal 'template/gleam' "$repo_path" .forgejo/renovate.jsonc
      replace_literal 'https://trev.zip/api/v1' "${web_url%/"$repo_path"}/api/v1" .forgejo/renovate.jsonc
    fi
    if [[ -d .github ]]; then
      read -r -p 'Non-GitHub origin detected. Delete .github? [y/N] ' reply || reply=
      if [[ $reply =~ ^[Yy]$ ]]; then
        rm -rf .github
        remove_checks actions-gh renovate-gh
      else
        read_secondary_repository GitHub
        "${new_git[@]}" remote add github "$secondary_remote"
        replace_literal "spotdemo4/$old_slug" "$secondary_repo_path" .github/renovate.jsonc
      fi
    fi
  fi
}

configure_editors() {
  local reply
  read -r -p 'Are you using Zed? [Y/n] ' reply || reply=
  if [[ $reply =~ ^[Nn]([Oo])?$ ]]; then
    rm -rf .zed
  fi

  read -r -p 'Are you using VS Code? [Y/n] ' reply || reply=
  if [[ $reply =~ ^[Nn]([Oo])?$ ]]; then
    rm -rf .vscode
  fi
}

# Formats the project and commits it as the new repository's root commit.
commit_new_repository() {
  local url file existing_tracked=()
  "${new_git[@]}" config core.bare false
  "${new_git[@]}" config user.name "$git_name"
  "${new_git[@]}" config user.email "$git_email"
  "${new_git[@]}" remote add origin "${remote_urls[0]}"
  for url in "${remote_urls[@]:1}"; do
    "${new_git[@]}" remote set-url --add origin "$url"
  done
  for url in "${push_urls[@]}"; do
    "${new_git[@]}" remote set-url --add --push origin "$url"
  done
  nix fmt

  "${new_git[@]}" add -A
  for file in "${tracked_files[@]}"; do
    if [[ -e $file || -L $file ]]; then
      existing_tracked+=("$file")
    fi
  done
  "${new_git[@]}" add -f -- "${existing_tracked[@]}"
  "${new_git[@]}" rm --cached --quiet -- init.sh
  git_as_user "${new_git[@]}" -c commit.gpgsign=false -c core.hooksPath=/dev/null commit --quiet --message 'chore: initialize project'
}

# Replaces .git with the new repository and removes the initializer.
activate_new_repository() {
  swap_started=true
  mv .git "$old_git_dir"
  if ! rm "$script_path"; then
    mv "$old_git_dir" .git
    die 'Unable to remove init.sh.'
  fi
  if ! mv "$new_git_dir" .git; then
    mv "$old_git_dir" .git
    git restore -- init.sh
    die 'Unable to activate the new Git repository.'
  fi
  swap_started=false
  rm -rf "$old_git_dir"
  trap - EXIT INT TERM HUP
}

main() {
  if [[ $# -ne 2 || -z $1 || -z $2 ]]; then
    die "Usage: ${0##*/} \"Title\" \"Description\""
  fi
  title=$1
  description=$2

  check_repository
  check_project
  check_worktree
  start_new_repository
  template_commit=$(find_template_commit)

  read -r -p 'Is this project a library? [y/N] ' reply || reply=
  is_library=false
  if [[ $reply =~ ^[Yy]([Ee][Ss])?$ ]]; then
    is_library=true
  fi

  changes_started=true
  apply_metadata
  if $is_library; then
    make_library
  fi
  write_readme
  configure_providers
  configure_editors
  commit_new_repository
  activate_new_repository

  printf 'Initialized %s (%s) from %s with a new root commit.\n' "$title" "$version" "$web_url"
}

# init.test.sh sources the script to test its functions.
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
