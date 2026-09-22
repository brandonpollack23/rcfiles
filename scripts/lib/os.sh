# Sourced by the scripts that do different things per OS. Each defines one
# function per OS, named <os>_<step>, and calls `for_os <step>`.
# Not executable, so mise doesn't list it as a task.

# mac, arch, debian or fedora (their derivatives too: Ubuntu, Manjaro...), or
# linux for any other Linux.
detect_os() {
  if [[ "$OSTYPE" == darwin* ]]; then
    echo mac
    return
  fi
  local ID="" ID_LIKE="" id
  test -f /etc/os-release && source /etc/os-release
  for id in $ID $ID_LIKE; do
    case "$id" in
      arch | debian | fedora) echo "$id" && return ;;
      ubuntu) echo debian && return ;;
    esac
  done
  echo linux
}

OS=$(detect_os)

# Runs <os>_<step> with the remaining arguments. On Linux, falls back to
# linux_<step> for what every distro does the same way.
for_os() { # <step> [args...]
  local fn="${OS}_$1"
  if ! declare -F "$fn" >/dev/null && [[ "$OS" != mac ]]; then fn="linux_$1"; fi
  if ! declare -F "$fn" >/dev/null; then
    echo "$(basename "$0"): $1 is not supported on $OS" >&2
    exit 1
  fi
  "$fn" "${@:2}"
}

# Installs Homebrew if it isn't there, and puts it on PATH for this script.
ensure_brew() {
  local brew
  for brew in brew /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    if command -v "$brew" >/dev/null; then
      eval "$("$brew" shellenv)"
      return
    fi
  done
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ensure_brew
}
