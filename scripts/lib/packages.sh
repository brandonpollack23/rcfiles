# Sourced by the scripts that read packages.txt (see its header for the format).
# Needs $OS from os.sh. Bash 3.2 compatible, like deps.sh.
# Not executable, so mise doesn't list it as a task.

packages_txt="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../../packages.txt"

# Every group in packages.txt, and its description, as "name<TAB>description".
all_groups() {
  sed -n 's/^\[\([a-z-]*\)\][[:space:]]*#*[[:space:]]*/\1	/p' "$packages_txt"
}

# Sorts each packages.txt line in the given groups into the array for the
# installer that installs it on this OS: brew, cask, mas, pacman or cargo.
read_packages() { # <group>...
  local groups=" $* " group="" line opt name arch formula as
  local words
  brew=() cask=() mas=() pacman=() cargo=()
  while read -r line; do
    # read -a splits without globbing, so [core] and friends stay as they are.
    read -ra words <<<"${line%%#*}"
    ((${#words[@]})) || continue
    if [[ "${words[0]}" == \[*\] ]]; then
      group=${words[0]//[][]/}
      continue
    fi
    [[ "$groups" == *" $group "* ]] || continue
    name=${words[0]} arch=${words[0]} formula=${words[0]} as=brew
    for opt in "${words[@]:1}"; do
      case "$opt" in
        arch=*) arch=${opt#*=} ;;
        brew=*) formula=${opt#*=} ;;
        cask) as=cask ;;
        cask=*) as=cask formula=${opt#*=} ;;
        mas=*) as=mas formula=${opt#*=} ;;
        cargo) as=cargo ;;
        cargo=*) as=cargo formula=${opt#*=} ;;
        *) echo "packages.txt: $name: unknown option $opt" >&2 && exit 1 ;;
      esac
    done
    if [[ "$as" == cargo ]]; then
      _add_package cargo "$formula"
    elif [[ "$OS" == arch ]]; then
      _add_package pacman "$arch"
    elif [[ "$OS" == mac ]]; then
      _add_package "$as" "$formula"
    elif [[ "$as" == brew ]]; then
      _add_package brew "$formula"
    fi
  done <"$packages_txt"
}

_add_package() { # <array> <comma-separated names, or - for none>
  local names name
  [[ "$2" == - ]] && return
  IFS=, read -ra names <<<"$2"
  for name in "${names[@]}"; do eval "$1+=(\"\$name\")"; done
}
