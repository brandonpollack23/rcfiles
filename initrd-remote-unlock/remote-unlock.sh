#!/usr/bin/env bash
# Written in [Amber](https://amber-lang.com/)
# version: 0.6.0-alpha
[ "$EUID" -ne 0 ] && { { command -v sudo >/dev/null 2>&1 && __sudo=sudo; } || { command -v doas >/dev/null 2>&1 && __sudo=doas; }; }
if [ -n "$ZSH_VERSION" ]; then
    EXEC_SHELL="zsh"
    IFS='.' read -A EXEC_SHELL_VERSION <<< "$ZSH_VERSION"
elif [ -n "$KSH_VERSION" ]; then
    EXEC_SHELL="ksh"
    __exec_shell_version="${.sh.version##*/}"
    IFS='.' read -a EXEC_SHELL_VERSION <<< "${__exec_shell_version%% *}"
else
    EXEC_SHELL="bash"
    EXEC_SHELL_VERSION=("${BASH_VERSINFO[0]}" "${BASH_VERSINFO[1]}" "${BASH_VERSINFO[2]}")
fi
# split(text: Text, delimiter: Text)
split__4_v0() {
    local text_92="${1}"
    local delimiter_93="${2}"
    local result_94=()
    # zsh uses -A for array, bash uses -a, ksh is VERY bad at splitting anything
    if [ "$([ "_${EXEC_SHELL}" != "_zsh" ]; echo $?)" != 0 ]; then
        IFS="${delimiter_93}" read -rd '' -A result_94 < <(printf %s "$text_92")
        __status=$?
    elif [ "$([ "_${EXEC_SHELL}" != "_ksh" ]; echo $?)" != 0 ]; then
        if [ "$([ "_${delimiter_93}" != "_
" ]; echo $?)" != 0 ]; then
            while read -r -d $'\n'; do result_94+=("$REPLY"); done < <(echo "$text_92")
            __status=$?
        else
            IFS="${delimiter_93}" read -rd '' -a result_94 < <(printf %s "$text_92")
            __status=$?
        fi
    elif [ "$([ "_${EXEC_SHELL}" != "_bash" ]; echo $?)" != 0 ]; then
        IFS="${delimiter_93}" read -rd '' -a result_94 < <(printf %s "$text_92")
        __status=$?
    fi
    ret_split4_v0=("${result_94[@]}")
    return 0
}

# split_lines(text: Text)
split_lines__5_v0() {
    local text_116="${1}"
    split__4_v0 "${text_116}" "
"
    ret_split_lines5_v0=("${ret_split4_v0[@]}")
    return 0
}

# join(list: [Text], delimiter: Text)
join__7_v0() {
    local list_113=("${!1}")
    local delimiter_114="${2}"
    local command_1
    command_1="$(IFS="${delimiter_114}" ; printf "%s
" "${list_113[*]}")"
    __status=$?
    ret_join7_v0="${command_1}"
    return 0
}

# trim(text: Text)
trim__10_v0() {
    local text_191="${1}"
    local result_192=""
    result_192="${text_191#${text_191%%[![:space:]]*}}"
    __status=$?
    result_192="${result_192%${result_192##*[![:space:]]}}"
    __status=$?
    ret_trim10_v0="${result_192}"
    return 0
}

# parse_int(text: Text)
parse_int__13_v0() {
    local text_95="${1}"
    [ -n "${text_95}" ] && [ "${text_95}" -eq "${text_95}" ] 2>/dev/null
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_parse_int13_v0=''
        return "${__status}"
    fi
    ret_parse_int13_v0="${text_95}"
    return 0
}

# text_contains(source: Text, search: Text)
text_contains__16_v0() {
    local source_194="${1}"
    local search_195="${2}"
    [[ "${source_194}" == *"${search_195}"* ]]
    __status=$?
    ret_text_contains16_v0="$(( __status == 0 ))"
    return 0
}

# starts_with(text: Text, prefix: Text)
starts_with__22_v0() {
    local text_39="${1}"
    local prefix_40="${2}"
    [[ "${text_39}" == "${prefix_40}"* ]]
    __status=$?
    ret_starts_with22_v0="$(( __status == 0 ))"
    return 0
}

# slice(text: Text, index: Int, length: Int)
slice__24_v0() {
    local text_41="${1}"
    local index_42="${2}"
    local length_43="${3}"
    local result_44=""
    if [ "$(( length_43 == 0 ))" != 0 ]; then
        local __length_2="${text_41}"
        length_43="$(( ${#__length_2} - index_42 ))"
    fi
    if [ "$(( length_43 <= 0 ))" != 0 ]; then
        ret_slice24_v0="${result_44}"
        return 0
    fi
    result_44="${text_41: ${index_42}: ${length_43}}"
    __status=$?
    ret_slice24_v0="${result_44}"
    return 0
}

# file_exists(path: Text)
file_exists__39_v0() {
    local path_97="${1}"
    [ -f "${path_97}" ]
    __status=$?
    ret_file_exists39_v0="$(( __status == 0 ))"
    return 0
}

# file_read(path: Text)
file_read__40_v0() {
    local path_187="${1}"
    local command_3
    command_3="$(< "${path_187}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_file_read40_v0=''
        return "${__status}"
    fi
    ret_file_read40_v0="${command_3}"
    return 0
}

# env_var_get(name: Text)
env_var_get__120_v0() {
    local name_100="${1}"
    if [ "$([ "_${EXEC_SHELL}" != "_bash" ]; echo $?)" != 0 ]; then
        local command_4
        command_4="$(printf "%s
" "${!name_100}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_env_var_get120_v0=''
            return "${__status}"
        fi
        ret_env_var_get120_v0="${command_4}"
        return 0
    elif [ "$([ "_${EXEC_SHELL}" != "_zsh" ]; echo $?)" != 0 ]; then
        local command_5
        command_5="$(printf "%s
" "${(P)name_100}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_env_var_get120_v0=''
            return "${__status}"
        fi
        ret_env_var_get120_v0="${command_5}"
        return 0
    elif [ "$([ "_${EXEC_SHELL}" != "_ksh" ]; echo $?)" != 0 ]; then
        local command_6
        command_6="$(eval "echo \${$name_100}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_env_var_get120_v0=''
            return "${__status}"
        fi
        ret_env_var_get120_v0="${command_6}"
        return 0
    fi
}

# is_command(command: Text)
is_command__122_v0() {
    local command_90="${1}"
    [ -x "$(command -v "${command_90}")" ]
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_is_command122_v0=0
        return 0
    fi
    ret_is_command122_v0=1
    return 0
}

# printf(format: Text, args: [Text])
printf__128_v0() {
    local format_54="${1}"
    local args_55=("${!2}")
    args_55=("${format_54}" "${args_55[@]}")
    __status=$?
    printf "${args_55[@]}"
    __status=$?
}

# echo_error(message: Text, exit_code: Int)
echo_error__138_v0() {
    local message_52="${1}"
    local exit_code_53="${2}"
    local array_7=("${message_52}")
    printf__128_v0 "\\x1b[1;3;97;41m%s\\x1b[0m
" array_7[@]
    if [ "$(( exit_code_53 > 0 ))" != 0 ]; then
        exit "${exit_code_53}"
    fi
}

# Running commands, with a dry-run mode that prints them instead.
# Not executable, so mise doesn't list it as a task.
# 
# The dry-run flag lives in an exported variable, not a module variable: amber
# compiles a module once per import path, each copy with its own variables.
# The repo root: mise sets it for every task.
# set_dry_run(dry: Bool)
set_dry_run__167_v0() {
    local dry_57="${1}"
    if [ "${dry_57}" != 0 ]; then
        export RCFILES_DRY_RUN=1
        __status=$?
    else
        unset RCFILES_DRY_RUN
        __status=$?
    fi
}

# is_dry_run()
is_dry_run__168_v0() {
    env_var_get__120_v0 "RCFILES_DRY_RUN"
    __status=$?
    local ret_env_var_get120_v0__24_18="${ret_env_var_get120_v0}"
    ret_is_dry_run168_v0="$([ "_${ret_env_var_get120_v0__24_18}" != "_1" ]; echo $?)"
    return 0
}

# True when stdin is a terminal, so the task can ask questions.
# Asks for the sudo password now, then keeps it cached in the background
# until this task's shell exits, so a long install doesn't ask again.
# keep_sudo()
keep_sudo__170_v0() {
    sudo -v
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_keep_sudo170_v0=''
        return "${__status}"
    fi
    (while sudo -n -v 2>/dev/null && kill -0 $$ 2>/dev/null; do sleep 50; done) >/dev/null 2>&1 &
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_keep_sudo170_v0=''
        return "${__status}"
    fi
}

# `text` as one shell word, safe to splice into a command line.
# quoted(text: Text)
quoted__171_v0() {
    local text_153="${1}"
    local command_8
    command_8="$(printf '%q' "${text_153}")"
    __status=$?
    ret_quoted171_v0="${command_8}"
    return 0
}

# Runs a shell command line in this shell (so `source` and `export` stick),
# or prints it when dry-running.
# run(cmd: Text)
run__172_v0() {
    local cmd_118="${1}"
    is_dry_run__168_v0 
    local ret_is_dry_run168_v0__48_8="${ret_is_dry_run168_v0}"
    if [ "${ret_is_dry_run168_v0__48_8}" != 0 ]; then
        printf '%s\n' "${cmd_118}"
        ret_run172_v0=''
        return 0
    fi
    eval "${cmd_118}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_run172_v0=''
        return "${__status}"
    fi
}

# The words of a mise `var=#true` argument (shell-quoted, like $usage_package).
# Which OS this is, and Homebrew. Imported by the tasks that do different
# things per OS; not executable, so mise doesn't list it as a task.
# The OS name for `ostype` ($OSTYPE) and `ids` (ID and ID_LIKE from
# /etc/os-release, space separated): mac, arch, debian or fedora (their
# derivatives too: Ubuntu, Manjaro...), or linux for any other Linux.
# Whether `version`, as `omarchy version` prints it ("4.0.4-1", or "dev (<hash>)"
# on the dev channel), is Omarchy 4 "Quattro" or later.
# is_quattro(version: Text)
is_quattro__187_v0() {
    local version_91="${1}"
    starts_with__22_v0 "${version_91}" "dev"
    local ret_starts_with22_v0__41_8="${ret_starts_with22_v0}"
    if [ "${ret_starts_with22_v0__41_8}" != 0 ]; then
        ret_is_quattro187_v0=1
        return 0
    fi
    if [ "$([ "_${version_91}" != "_" ]; echo $?)" != 0 ]; then
        ret_is_quattro187_v0=0
        return 0
    fi
    split__4_v0 "${version_91}" "."
    local ret_split4_v0__47_29=("${ret_split4_v0[@]}")
    parse_int__13_v0 "${ret_split4_v0__47_29[0]?"Index out of bounds (at scripts/./lib/os.ab:47:49)"}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_is_quattro187_v0=0
        return 0
    fi
    local major_96="${ret_parse_int13_v0}"
    ret_is_quattro187_v0="$(( major_96 >= 4 ))"
    return 0
}

# True on Omarchy 4 or later. Earlier Omarchy lived in ~/.local/share/omarchy
# and had no `omarchy` command, only the omarchy-* scripts.
# is_omarchy()
is_omarchy__188_v0() {
    is_command__122_v0 "omarchy"
    local ret_is_command122_v0__56_12="${ret_is_command122_v0}"
    if [ "$(( ! ret_is_command122_v0__56_12 ))" != 0 ]; then
        ret_is_omarchy188_v0=0
        return 0
    fi
    local command_9
    command_9="$(omarchy version 2>/dev/null)"
    __status=$?
    is_quattro__187_v0 "${command_9}"
    ret_is_omarchy188_v0="${ret_is_quattro187_v0}"
    return 0
}

# The brew command if Homebrew is installed, else "".
# Installs Homebrew if it isn't there, and puts it on PATH for this script.
# What `mise run remote-unlock` installs to unlock the LUKS root over
# Tailscale SSH at boot (initrd-remote-unlock/README.md explains it).
# Not executable, so mise doesn't list it as a task.
# mkinitcpio-tailscale (AUR) has the tailscale hook, mkinitcpio-extras netconf.
__PACKAGES_3=("mkinitcpio-tailscale" "mkinitcpio-extras")
# Omarchy's drop-in, which sets HOOKS= outright, and the kernel command line
# limine-update bakes into the UKI.
__OMARCHY_HOOKS_4="/etc/mkinitcpio.conf.d/omarchy_hooks.conf"
__LIMINE_DEFAULTS_5="/etc/default/limine"
# setup-initcpio-tailscale writes the initrd node's key here.
__NODE_STATE_6="/etc/initcpio/tailscale/tailscaled.state"
# DHCP on the one wired port, which is eth0 in the initramfs: it has no udev
# rule to rename interfaces. Capped at 15s so a boot with no cable doesn't
# hold the passphrase prompt back for netconf's default 120.
__DEFAULT_IP_7=":::::eth0:dhcp"
# The line appended to /etc/default/limine.
# cmdline_line(ip: Text)
cmdline_line__197_v0() {
    local ip_196="${1}"
    ret_cmdline_line197_v0="KERNEL_CMDLINE[default]+=\" ip=${ip_196} netconf_timeout=15\""
    return 0
}

# The task's flags, read from its own arguments rather than mise's usage_*
# variables, so the compiled initrd-remote-unlock/remote-unlock.sh takes them
# too (mise passes them through as well as parsing them). args[0] is the
# script, or bash under `amber run`. Returns [dry_run, force, ip], the first
# two "true" or "false"; or ["error", <message>, ""].
# parse_flags(args: [Text])
parse_flags__198_v0() {
    local args_32=("${!1}")
    local dry_run_33="false"
    local force_34="false"
    local ip_35="${__DEFAULT_IP_7}"
    local wants_ip_36=0
    i_38=0;
    for arg_37 in "${args_32[@]}"; do
        if [ "$(( i_38 > 0 ))" != 0 ]; then
            starts_with__22_v0 "${arg_37}" "--ip="
            local ret_starts_with22_v0__54_17="${ret_starts_with22_v0}"
            if [ "${wants_ip_36}" != 0 ]; then
                ip_35="${arg_37}"
                wants_ip_36=0
            elif [ "$(( $([ "_${arg_37}" != "_-n" ]; echo $?) || $([ "_${arg_37}" != "_--dry-run" ]; echo $?) ))" != 0 ]; then
                dry_run_33="true"
            elif [ "$(( $([ "_${arg_37}" != "_-f" ]; echo $?) || $([ "_${arg_37}" != "_--force" ]; echo $?) ))" != 0 ]; then
                force_34="true"
            elif [ "$([ "_${arg_37}" != "_--ip" ]; echo $?)" != 0 ]; then
                wants_ip_36=1
            elif [ "${ret_starts_with22_v0__54_17}" != 0 ]; then
                slice__24_v0 "${arg_37}" 5 0
                ip_35="${ret_slice24_v0}"
            else
                ret_parse_flags198_v0=("error" "unknown argument ${arg_37} (flags: -n/--dry-run, -f/--force, --ip <ip>)" "")
                return 0
            fi
        fi
        (( i_38++ )) || true
    done
    if [ "${wants_ip_36}" != 0 ]; then
        ret_parse_flags198_v0=("error" "--ip needs a value, like :::::eth0:dhcp or dhcp" "")
        return 0
    fi
    ret_parse_flags198_v0=("${dry_run_33}" "${force_34}" "${ip_35}")
    return 0
}

# Whether a /etc/default/limine already passes ip= (in any form), outside
# comments. Looks for " ip=" and "\"ip=", so skip= and the like don't count.
# has_ip_param(limine: Text)
has_ip_param__199_v0() {
    local limine_189="${1}"
    split_lines__5_v0 "${limine_189}"
    local ret_split_lines5_v0__72_17=("${ret_split_lines5_v0[@]}")
    for line_190 in "${ret_split_lines5_v0__72_17[@]}"; do
        trim__10_v0 "${line_190}"
        local stripped_193="${ret_trim10_v0}"
        starts_with__22_v0 "${stripped_193}" "#"
        local ret_starts_with22_v0__74_16="${ret_starts_with22_v0}"
        if [ "$(( ! ret_starts_with22_v0__74_16 ))" != 0 ]; then
            text_contains__16_v0 "${stripped_193}" " ip="
            local ret_text_contains16_v0__75_16="${ret_text_contains16_v0}"
            text_contains__16_v0 "${stripped_193}" "\"ip="
            local ret_text_contains16_v0__75_51="${ret_text_contains16_v0}"
            if [ "$(( ret_text_contains16_v0__75_16 || ret_text_contains16_v0__75_51 ))" != 0 ]; then
                ret_has_ip_param199_v0=1
                return 0
            fi
        fi
    done
    ret_has_ip_param199_v0=0
    return 0
}

# #!/usr/bin/env -S sh -c 'exec amber run --target bash-3.2 "$0" -- "$@"'
# MISE description="Unlock Omarchy's LUKS root over Tailscale SSH at boot: installs the initramfs hooks in initrd-remote-unlock/ and rebuilds the boot image"
# USAGE flag "-n --dry-run" help="Print the commands instead of running them"
# USAGE flag "-f --force" help="Rebuild the boot image even when nothing changed"
# USAGE flag "--ip <ip>" default=":::::eth0:dhcp" help="The ip= kernel parameter for the initramfs network (netconf); ip=dhcp tries every port"
# Safe to run again: each step is skipped when it is already done. The steps,
# and what they do to the boot, are in initrd-remote-unlock/README.md.
# 
# Also compiled to initrd-remote-unlock/remote-unlock.sh, for a machine
# without this repo's mise setup; `mise run lint` checks that it is current.
# The hooks and the kernel command line here are Omarchy's: a busybox
# initramfs with the encrypt hook, built into a UKI by limine-update.
# ensure_supported()
ensure_supported__203_v0() {
    is_omarchy__188_v0 
    local ret_is_omarchy188_v0__23_12="${ret_is_omarchy188_v0}"
    if [ "$(( ! ret_is_omarchy188_v0__23_12 ))" != 0 ]; then
        echo_error__138_v0 "remote-unlock: this is for Omarchy (4 or later)" 1
    fi
    file_exists__39_v0 "${__OMARCHY_HOOKS_4}"
    local ret_file_exists39_v0__26_12="${ret_file_exists39_v0}"
    file_exists__39_v0 "${__LIMINE_DEFAULTS_5}"
    local ret_file_exists39_v0__26_46="${ret_file_exists39_v0}"
    is_command__122_v0 "limine-update"
    local ret_is_command122_v0__26_82="${ret_is_command122_v0}"
    if [ "$(( $(( $(( ! ret_file_exists39_v0__26_12 )) || $(( ! ret_file_exists39_v0__26_46 )) )) || $(( ! ret_is_command122_v0__26_82 )) ))" != 0 ]; then
        echo_error__138_v0 "remote-unlock: expected ${__OMARCHY_HOOKS_4}, ${__LIMINE_DEFAULTS_5} and limine-update, Omarchy's Limine UKI setup" 1
    fi
    grep -Eq '^HOOKS=.*[( ]encrypt[ )]' ${__OMARCHY_HOOKS_4}
    __status=$?
    if [ "$(( __status != 0 ))" != 0 ]; then
        echo_error__138_v0 "remote-unlock: ${__OMARCHY_HOOKS_4} has no busybox 'encrypt' hook, so there is no LUKS prompt to answer" 1
    fi
    is_command__122_v0 "yay"
    local ret_is_command122_v0__33_12="${ret_is_command122_v0}"
    if [ "$(( ! ret_is_command122_v0__33_12 ))" != 0 ]; then
        echo_error__138_v0 "remote-unlock: needs yay for the AUR package mkinitcpio-tailscale" 1
    fi
}

# True when it installed something, so the image needs a rebuild.
# install_packages()
install_packages__204_v0() {
    join__7_v0 __PACKAGES_3[@] " "
    local ret_join7_v0__40_45="${ret_join7_v0}"
    local command_18
    command_18="$(eval "pacman -T ${ret_join7_v0__40_45}")"
    __status=$?
    local listed_115="${command_18}"
    split_lines__5_v0 "${listed_115}"
    local missing_117=("${ret_split_lines5_v0[@]}")
    local __length_19=("${missing_117[@]}")
    if [ "$(( ${#__length_19[@]} == 0 ))" != 0 ]; then
        ret_install_packages204_v0=0
        return 0
    fi
    join__7_v0 missing_117[@] " "
    local ret_join7_v0__45_27="${ret_join7_v0}"
    run__172_v0 "yay -S --needed ${ret_join7_v0__45_27}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_packages204_v0=''
        return "${__status}"
    fi
    ret_install_packages204_v0=1
    return 0
}

# Registers the initramfs as its own tailnet node (<hostname>-initrd), which
# asks you to log in. The node's key is root-only, hence sudo to look for it.
# register_node()
register_node__205_v0() {
    sudo -n test -s ${__NODE_STATE_6} 2>/dev/null
    __status=$?
    if [ "$(( __status == 0 ))" != 0 ]; then
        ret_register_node205_v0=0
        return 0
    fi
    # A dry run doesn't ask for the sudo password, so it can't tell.
    is_dry_run__168_v0 
    local ret_is_dry_run168_v0__57_8="${ret_is_dry_run168_v0}"
    if [ "${ret_is_dry_run168_v0__57_8}" != 0 ]; then
        echo "sudo setup-initcpio-tailscale  # unless registered already"
        ret_register_node205_v0=1
        return 0
    fi
    run__172_v0 "sudo setup-initcpio-tailscale"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_register_node205_v0=''
        return "${__status}"
    fi
    ret_register_node205_v0=1
    return 0
}

# The remote-unlock hook, and the drop-in that puts netconf, remote-unlock and
# tailscale before encrypt.
# install_hooks()
install_hooks__206_v0() {
    files_dir__207_v0 
    local dir_149="${ret_files_dir207_v0}"
    install_file__208_v0 "${dir_149}/remote-unlock.install" "/etc/initcpio/install/remote-unlock" "644"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_hooks206_v0=''
        return "${__status}"
    fi
    local hook_154="${ret_install_file208_v0}"
    install_file__208_v0 "${dir_149}/remote-unlock.login" "/etc/initcpio/remote-unlock/login" "755"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_hooks206_v0=''
        return "${__status}"
    fi
    local login_155="${ret_install_file208_v0}"
    install_file__208_v0 "${dir_149}/zz_tailscale.conf" "/etc/mkinitcpio.conf.d/zz_tailscale.conf" "644"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_hooks206_v0=''
        return "${__status}"
    fi
    local drop_in_156="${ret_install_file208_v0}"
    ret_install_hooks206_v0="$(( $(( hook_154 || login_155 )) || drop_in_156 ))"
    return 0
}

# initrd-remote-unlock/ in the repo mise runs the task from, or else the
# directory the compiled remote-unlock.sh sits in.
# files_dir()
files_dir__207_v0() {
    env_var_get__120_v0 "MISE_CONFIG_ROOT"
    __status=$?
    local root_148="${ret_env_var_get120_v0}"
    if [ "$([ "_${root_148}" == "_" ]; echo $?)" != 0 ]; then
        ret_files_dir207_v0="${root_148}/initrd-remote-unlock"
        return 0
    fi
    local command_20
    command_20="$(cd "$(dirname "$0")" && pwd)"
    __status=$?
    ret_files_dir207_v0="${command_20}"
    return 0
}

# install_file(src: Text, dst: Text, mode: Text)
install_file__208_v0() {
    local src_150="${1}"
    local dst_151="${2}"
    local mode_152="${3}"
    cmp -s ${src_150} ${dst_151}
    __status=$?
    if [ "$(( __status == 0 ))" != 0 ]; then
        ret_install_file208_v0=0
        return 0
    fi
    quoted__171_v0 "${src_150}"
    local ret_quoted171_v0__90_34="${ret_quoted171_v0}"
    quoted__171_v0 "${dst_151}"
    local ret_quoted171_v0__90_48="${ret_quoted171_v0}"
    run__172_v0 "sudo install -Dm${mode_152} ${ret_quoted171_v0__90_34} ${ret_quoted171_v0__90_48}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_file208_v0=''
        return "${__status}"
    fi
    ret_install_file208_v0=1
    return 0
}

# Appends the ip= line to /etc/default/limine, unless it already has one
# (which is kept, even if it differs from --ip). The leading newline keeps
# it off the last line when the file doesn't end in one.
# add_ip_param(ip: Text)
add_ip_param__209_v0() {
    local ip_186="${1}"
    file_read__40_v0 "${__LIMINE_DEFAULTS_5}"
    __status=$?
    local limine_188="${ret_file_read40_v0}"
    has_ip_param__199_v0 "${limine_188}"
    local ret_has_ip_param199_v0__99_8="${ret_has_ip_param199_v0}"
    if [ "${ret_has_ip_param199_v0__99_8}" != 0 ]; then
        echo "remote-unlock: ${__LIMINE_DEFAULTS_5} already sets ip=, keeping it"
        ret_add_ip_param209_v0=0
        return 0
    fi
    cmdline_line__197_v0 "${ip_186}"
    local ret_cmdline_line197_v0__103_69="${ret_cmdline_line197_v0}"
    quoted__171_v0 "
""${ret_cmdline_line197_v0__103_69}"
    local ret_quoted171_v0__103_55="${ret_quoted171_v0}"
    run__172_v0 "sudo tee -a ${__LIMINE_DEFAULTS_5} >/dev/null <<<${ret_quoted171_v0__103_55}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_add_ip_param209_v0=''
        return "${__status}"
    fi
    ret_add_ip_param209_v0=1
    return 0
}

# limine-update rebuilds the initramfs and the UKI it goes in, with the kernel
# command line from /etc/default/limine; mkinitcpio -P does nothing here.
# --check then says the image can't be inspected: it looks for a separate
# initramfs file, not one inside the UKI.
# rebuild(changed: Bool)
rebuild__210_v0() {
    local changed_199="${1}"
    if [ "${changed_199}" != 0 ]; then
        run__172_v0 "sudo limine-update"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_rebuild210_v0=''
            return "${__status}"
        fi
    else
        echo "remote-unlock: nothing changed, the boot image is up to date (--force rebuilds it anyway)"
    fi
    run__172_v0 "sudo setup-initcpio-tailscale --check"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rebuild210_v0=''
        return "${__status}"
    fi
}

# remind()
remind__211_v0() {
    printf '%s\n' ""
    echo "remote-unlock: done. In the Tailscale admin console, make sure <hostname>-initrd"
    echo "  has key expiry disabled and that your SSH policy lets you in as root."
    echo "  Then reboot and, at the passphrase prompt, from another machine:"
    echo "    ssh root@<hostname>-initrd"
    echo "  Test it at the machine first: typing the passphrase there still works."
}

typeset -r args_12=("$0" "$@")
parse_flags__198_v0 args_12[@]
flags_45=("${ret_parse_flags198_v0[@]}")
if [ "$([ "_${flags_45[0]?"Index out of bounds (at scripts/remote-unlock.ab:131:14)"}" != "_error" ]; echo $?)" != 0 ]; then
    echo_error__138_v0 "remote-unlock: ${flags_45[1]?"Index out of bounds (at scripts/remote-unlock.ab:132:43)"}" 1
fi
set_dry_run__167_v0 "$([ "_${flags_45[0]?"Index out of bounds (at scripts/remote-unlock.ab:134:23)"}" != "_true" ]; echo $?)"
force_58="$([ "_${flags_45[1]?"Index out of bounds (at scripts/remote-unlock.ab:135:25)"}" != "_true" ]; echo $?)"
ip_59="${flags_45[2]?"Index out of bounds (at scripts/remote-unlock.ab:136:22)"}"
ensure_supported__203_v0 
is_dry_run__168_v0 
ret_is_dry_run168_v0__138_12="${ret_is_dry_run168_v0}"
if [ "$(( ! ret_is_dry_run168_v0__138_12 ))" != 0 ]; then
    keep_sudo__170_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        exit "${__status}"
    fi
fi
install_packages__204_v0 
__status=$?
if [ "${__status}" != 0 ]; then
    exit "${__status}"
fi
installed_119="${ret_install_packages204_v0}"
register_node__205_v0 
__status=$?
if [ "${__status}" != 0 ]; then
    exit "${__status}"
fi
registered_120="${ret_register_node205_v0}"
install_hooks__206_v0 
__status=$?
if [ "${__status}" != 0 ]; then
    exit "${__status}"
fi
hooks_157="${ret_install_hooks206_v0}"
add_ip_param__209_v0 "${ip_59}"
__status=$?
if [ "${__status}" != 0 ]; then
    exit "${__status}"
fi
cmdline_197="${ret_add_ip_param209_v0}"
rebuild__210_v0 "$(( $(( $(( $(( force_58 || installed_119 )) || registered_120 )) || hooks_157 )) || cmdline_197 ))"
__status=$?
if [ "${__status}" != 0 ]; then
    exit "${__status}"
fi
is_dry_run__168_v0 
ret_is_dry_run168_v0__146_12="${ret_is_dry_run168_v0}"
if [ "$(( ! ret_is_dry_run168_v0__146_12 ))" != 0 ]; then
    remind__211_v0 
fi
