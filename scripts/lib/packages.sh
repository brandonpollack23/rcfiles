# Sourced by the scripts that read packages.toml (see its header for the format).
# Needs $OS from os.sh. Bash 3.2 compatible, like deps.sh.
# Not executable, so mise doesn't list it as a task.

packages_toml="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../../packages.toml"

# yq (mikefarah's) on packages.toml. mise installs it the first time, the same
# way on every OS, before there's a package manager to get it from.
packages_yq() { # <expression>
  mise exec yq@4 -- yq -p toml -o yaml "$1" "$packages_toml"
}

# Every group in packages.toml, and its description, as "name<TAB>description".
all_groups() {
  packages_yq '.groups | to_entries[] | .key + "	" + .value'
}

# Sorts each package in the given groups into the array for the installer that
# installs it on this OS: brew, cask, mas, pacman or cargo.
read_packages() { # <group>...
  local groups=" $* " lines group name to_arch to_brew to_cask to_mas to_cargo
  brew=() cask=() mas=() pacman=() cargo=()
  # One line per package: group|name|arch|brew|cask|mas|cargo, each option
  # empty when it isn't set, and a list of Arch names joined with commas.
  lines=$(packages_yq '
    .packages | to_entries[] | .key as $group | .value | to_entries[] |
    [$group, .key] +
    ({"arch": "", "brew": "", "cask": "", "mas": "", "cargo": ""} * .value
      | [.arch, .brew, .cask, .mas, .cargo]
      | (.[] | select(tag == "!!seq")) |= join(",")
      | map(tostring))
    | join("|")')
  while IFS='|' read -r group name to_arch to_brew to_cask to_mas to_cargo; do
    [[ "$groups" == *" $group "* ]] || continue
    if [[ -n "$to_cargo" && "$to_cargo" != false ]]; then
      [[ "$to_cargo" == true ]] && to_cargo=$name
      _add_package cargo "$to_cargo"
    elif [[ "$OS" == arch ]]; then
      [[ "$to_arch" == false ]] || _add_package pacman "${to_arch:-$name}"
    elif [[ -n "$to_mas" ]]; then
      [[ "$OS" != mac ]] || _add_package mas "$to_mas"
    elif [[ -n "$to_cask" && "$to_cask" != false ]]; then
      [[ "$to_cask" == true ]] && to_cask=$name
      [[ "$OS" != mac ]] || _add_package cask "$to_cask"
    elif [[ "$to_brew" != false ]]; then
      _add_package brew "${to_brew:-$name}"
    fi
  done <<<"$lines"
}

_add_package() { # <array> <comma-separated names>
  local names name
  IFS=, read -ra names <<<"$2"
  for name in "${names[@]}"; do eval "$1+=(\"\$name\")"; done
}
