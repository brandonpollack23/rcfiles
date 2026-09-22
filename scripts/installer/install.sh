#!/usr/bin/env bash
# GENERATED from scripts/installer/main.ab by scripts/build.ab. Edit the .ab sources, then run: mise run build
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
    local text_370="${1}"
    local delimiter_371="${2}"
    local result_372=()
    # zsh uses -A for array, bash uses -a, ksh is VERY bad at splitting anything
    if [ "$([ "_${EXEC_SHELL}" != "_zsh" ]; echo $?)" != 0 ]; then
        IFS="${delimiter_371}" read -rd '' -A result_372 < <(printf %s "$text_370")
        __status=$?
    elif [ "$([ "_${EXEC_SHELL}" != "_ksh" ]; echo $?)" != 0 ]; then
        if [ "$([ "_${delimiter_371}" != "_
" ]; echo $?)" != 0 ]; then
            while read -r -d $'\n'; do result_372+=("$REPLY"); done < <(echo "$text_370")
            __status=$?
        else
            IFS="${delimiter_371}" read -rd '' -a result_372 < <(printf %s "$text_370")
            __status=$?
        fi
    elif [ "$([ "_${EXEC_SHELL}" != "_bash" ]; echo $?)" != 0 ]; then
        IFS="${delimiter_371}" read -rd '' -a result_372 < <(printf %s "$text_370")
        __status=$?
    fi
    ret_split4_v0=("${result_372[@]}")
    return 0
}

# split_lines(text: Text)
split_lines__5_v0() {
    local text_473="${1}"
    split__4_v0 "${text_473}" "
"
    ret_split_lines5_v0=("${ret_split4_v0[@]}")
    return 0
}

# join(list: [Text], delimiter: Text)
join__7_v0() {
    local list_290=("${!1}")
    local delimiter_291="${2}"
    local command_1
    command_1="$(IFS="${delimiter_291}" ; printf "%s
" "${list_290[*]}")"
    __status=$?
    ret_join7_v0="${command_1}"
    return 0
}

# trim(text: Text)
trim__10_v0() {
    local text_285="${1}"
    local result_286=""
    result_286="${text_285#${text_285%%[![:space:]]*}}"
    __status=$?
    result_286="${result_286%${result_286##*[![:space:]]}}"
    __status=$?
    ret_trim10_v0="${result_286}"
    return 0
}

# lowercase(text: Text)
lowercase__11_v0() {
    local text_53="${1}"
    left_comp=("${EXEC_SHELL_VERSION[@]}")
    right_comp=(4 3)
    local comp
    comp="$(
        # Compare if left array < right array
        len_comp="$( (( "${#left_comp[@]}" < "${#right_comp[@]}" )) && echo "${#left_comp[@]}"|| echo "${#right_comp[@]}")"
        for (( i=0; i<len_comp; i++ )); do
            left="${left_comp[i]?"Index out of bounds (at unknown)"}"
            right="${right_comp[i]?"Index out of bounds (at unknown)"}"
            if (( "${left}" < "${right}" )); then
                echo 1
                exit
            elif (( "${left}" > "${right}" )); then
                echo 0
                exit
            fi
        done
        (( "${#left_comp[@]}" < "${#right_comp[@]}" )) && echo 1 || echo 0
)"
    if [ "$(( $([ "_${EXEC_SHELL}" != "_bash" ]; echo $?) && comp ))" != 0 ]; then
        text_53="$(printf '%s' "${text_53}" | tr '[:upper:]' '[:lower:]')"
        __status=$?
    else
        typeset -l text_53
            text_53="${text_53}"
        __status=$?
    fi
    ret_lowercase11_v0="${text_53}"
    return 0
}

# starts_with(text: Text, prefix: Text)
starts_with__22_v0() {
    local text_93="${1}"
    local prefix_94="${2}"
    [[ "${text_93}" == "${prefix_94}"* ]]
    __status=$?
    ret_starts_with22_v0="$(( __status == 0 ))"
    return 0
}

# dir_exists(path: Text)
dir_exists__38_v0() {
    local path_313="${1}"
    [ -d "${path_313}" ]
    __status=$?
    ret_dir_exists38_v0="$(( __status == 0 ))"
    return 0
}

# file_exists(path: Text)
file_exists__39_v0() {
    local path_70="${1}"
    [ -f "${path_70}" ]
    __status=$?
    ret_file_exists39_v0="$(( __status == 0 ))"
    return 0
}

# file_read(path: Text)
file_read__40_v0() {
    local path_471="${1}"
    local command_3
    command_3="$(< "${path_471}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_file_read40_v0=''
        return "${__status}"
    fi
    ret_file_read40_v0="${command_3}"
    return 0
}

# file_append(path: Text, content: Text)
file_append__42_v0() {
    local path_146="${1}"
    local content_147="${2}"
    local command_4
    command_4="$(printf '%s
' "${content_147}" >> "${path_146}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_file_append42_v0=''
        return "${__status}"
    fi
    ret_file_append42_v0="${command_4}"
    return 0
}

# file_glob_all(paths: [Text])
file_glob_all__49_v0() {
    local paths_279=("${!1}")
    local files_280=()
    for path_281 in "${paths_279[@]}"; do
        local __ls_path_8="${path_281}"
        __ls_path_8="${__ls_path_8//\\/\\\\}"
        (( 1 )) && __ls_all_8="-A" || __ls_all_8=""
        local __ls_8=()
        LC_ALL=C IFS=$'\n' read -rd '' -a __ls_8 < <(IFS=$'\n'; LC_ALL=C ls -1 ${__ls_all_8} ${__ls_path_8} 2>/dev/null
        __status=$?
        if [ "${__status}" != 0 ]; then
            # this can fail when no file could be found
            continue
        fi
        );
        files_280+=("${__ls_8[@]}")
    done
    ret_file_glob_all49_v0=("${files_280[@]}")
    return 0
}

# file_glob(path: Text)
file_glob__50_v0() {
    local path_278="${1}"
    local array_9=("${path_278}")
    file_glob_all__49_v0 array_9[@]
    ret_file_glob50_v0=("${ret_file_glob_all49_v0[@]}")
    return 0
}

# env_var_get(name: Text)
env_var_get__120_v0() {
    local name_43="${1}"
    if [ "$([ "_${EXEC_SHELL}" != "_bash" ]; echo $?)" != 0 ]; then
        local command_10
        command_10="$(printf "%s
" "${!name_43}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_env_var_get120_v0=''
            return "${__status}"
        fi
        ret_env_var_get120_v0="${command_10}"
        return 0
    elif [ "$([ "_${EXEC_SHELL}" != "_zsh" ]; echo $?)" != 0 ]; then
        local command_11
        command_11="$(printf "%s
" "${(P)name_43}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_env_var_get120_v0=''
            return "${__status}"
        fi
        ret_env_var_get120_v0="${command_11}"
        return 0
    elif [ "$([ "_${EXEC_SHELL}" != "_ksh" ]; echo $?)" != 0 ]; then
        local command_12
        command_12="$(eval "echo \${$name_43}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_env_var_get120_v0=''
            return "${__status}"
        fi
        ret_env_var_get120_v0="${command_12}"
        return 0
    fi
}

# is_command(command: Text)
is_command__122_v0() {
    local command_139="${1}"
    [ -x "$(command -v "${command_139}")" ]
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_is_command122_v0=0
        return 0
    fi
    ret_is_command122_v0=1
    return 0
}

# input_confirm(prompt: Text, default_yes: Bool)
input_confirm__125_v0() {
    local prompt_50="${1}"
    local default_yes_51="${2}"
    local choice_default_52
    choice_default_52="$(if [ "${default_yes_51}" != 0 ]; then echo " [\\x1b[1mY/\\x1b[0mn]"; else echo " [y/\\x1b[1mN\\x1b[0m]"; fi)"
    printf "\x1b[1m${prompt_50}\x1b[0m${choice_default_52}"
    __status=$?
    if [ "$([ "_${EXEC_SHELL}" != "_zsh" ]; echo $?)" != 0 ]; then
        read -k 1 -u 0 -s || read -k 1 -u 0 -s < /dev/tty
        __status=$?
    elif [ "$([ "_${EXEC_SHELL}" != "_bash" ]; echo $?)" != 0 ]; then
        read -s -n 1 || read -s -n 1 < /dev/tty
        __status=$?
    elif [ "$([ "_${EXEC_SHELL}" != "_ksh" ]; echo $?)" != 0 ]; then
        read -n 1 || read -n 1 < /dev/tty
        __status=$?
    fi
    printf "
"
    __status=$?
    local command_13
    command_13="$(printf '%s
' $REPLY)"
    __status=$?
    lowercase__11_v0 "${command_13}"
    local result_54="${ret_lowercase11_v0}"
    ret_input_confirm125_v0="$(( $([ "_${result_54}" != "_y" ]; echo $?) || $(( $([ "_${result_54}" != "_" ]; echo $?) && default_yes_51 )) ))"
    return 0
}

# is_root()
is_root__127_v0() {
    local command_14
    command_14="$(id -u)"
    __status=$?
    if [ "$([ "_${command_14}" != "_0" ]; echo $?)" != 0 ]; then
        ret_is_root127_v0=1
        return 0
    fi
    ret_is_root127_v0=0
    return 0
}

# printf(format: Text, args: [Text])
printf__128_v0() {
    local format_64="${1}"
    local args_65=("${!2}")
    args_65=("${format_64}" "${args_65[@]}")
    __status=$?
    printf "${args_65[@]}"
    __status=$?
}

# echo_success(message: Text)
echo_success__136_v0() {
    local message_477="${1}"
    local array_15=("${message_477}")
    printf__128_v0 "\\x1b[1;3;97;42m%s\\x1b[0m
" array_15[@]
}

# echo_error(message: Text, exit_code: Int)
echo_error__138_v0() {
    local message_62="${1}"
    local exit_code_63="${2}"
    local array_16=("${message_62}")
    printf__128_v0 "\\x1b[1;3;97;41m%s\\x1b[0m
" array_16[@]
    if [ "$(( exit_code_63 > 0 ))" != 0 ]; then
        exit "${exit_code_63}"
    fi
}

# Every change the installer makes to the machine goes through run(), so
# --dry-run can print the whole sequence instead. Read-only probes (is a
# program installed, does a unit exist) run directly.
# 
# The dry-run flag and the list of problems live in exported variables and a
# file, not in module variables: amber compiles a module once per import path
# ("./src/run.ab" from main.ab, "./run.ab" from src/links.ab), and each copy
# would get its own variables.
# Call once, first thing in main: it also clears a flag inherited from the
# environment and starts an empty problem list.
# init_run_state(dry: Bool)
init_run_state__169_v0() {
    local dry_39="${1}"
    if [ "${dry_39}" != 0 ]; then
        export INSTALL_DRY_RUN=1
        __status=$?
    else
        unset INSTALL_DRY_RUN
        __status=$?
    fi
    local command_17
    command_17="$(mktemp -t install-problems.XXXXXX)"
    __status=$?
    local problems_file_40="${command_17}"
    export INSTALL_PROBLEMS_FILE="${problems_file_40}"
    __status=$?
}

# is_dry_run()
is_dry_run__170_v0() {
    env_var_get__120_v0 "INSTALL_DRY_RUN"
    __status=$?
    local ret_env_var_get120_v0__27_18="${ret_env_var_get120_v0}"
    ret_is_dry_run170_v0="$([ "_${ret_env_var_get120_v0__27_18}" != "_1" ]; echo $?)"
    return 0
}

# `text` as one shell word, safe to splice into a command line.
# quoted(text: Text)
quoted__171_v0() {
    local text_445="${1}"
    local command_18
    command_18="$(printf '%q' "${text_445}")"
    __status=$?
    ret_quoted171_v0="${command_18}"
    return 0
}

# "sudo " unless already root.
# `cmd` run as root: through sudo, or directly when the installer is root.
# Runs a shell command line (in this shell, so `source` and `export` stick).
# run(cmd: Text)
run__174_v0() {
    local cmd_447="${1}"
    is_dry_run__170_v0 
    local ret_is_dry_run170_v0__50_8="${ret_is_dry_run170_v0}"
    if [ "${ret_is_dry_run170_v0__50_8}" != 0 ]; then
        echo "[dry-run] ${cmd_447}"
        ret_run174_v0=''
        return 0
    fi
    eval "${cmd_447}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_run174_v0=''
        return "${__status}"
    fi
}

# heading(text: Text)
heading__175_v0() {
    local text_321="${1}"
    printf '%s\n' ""
    printf '\033[1;34m==> %s\033[0m
' "${text_321}"
    __status=$?
}

# warn(text: Text)
warn__176_v0() {
    local text_449="${1}"
    printf '\033[1;33mwarning:\033[0m %s
' "${text_449}" >&2
    __status=$?
}

# Problems the run carried on past, reported together at the end.
# note_problem(text: Text)
note_problem__177_v0() {
    local text_458="${1}"
    warn__176_v0 "${text_458}"
    env_var_get__120_v0 "INSTALL_PROBLEMS_FILE"
    __status=$?
    local problems_file_459="${ret_env_var_get120_v0}"
    if [ "$([ "_${problems_file_459}" == "_" ]; echo $?)" != 0 ]; then
        file_append__42_v0 "${problems_file_459}" "${text_458}"
        __status=$?
    fi
}

# problems()
problems__178_v0() {
    env_var_get__120_v0 "INSTALL_PROBLEMS_FILE"
    __status=$?
    local problems_file_470="${ret_env_var_get120_v0}"
    if [ "$([ "_${problems_file_470}" != "_" ]; echo $?)" != 0 ]; then
        ret_problems178_v0=()
        return 0
    fi
    file_read__40_v0 "${problems_file_470}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_problems178_v0=()
        return 0
    fi
    local listed_472="${ret_file_read40_v0}"
    rm -f "${problems_file_470}"
    __status=$?
    if [ "$([ "_${listed_472}" != "_" ]; echo $?)" != 0 ]; then
        ret_problems178_v0=()
        return 0
    fi
    split_lines__5_v0 "${listed_472}"
    ret_problems178_v0=("${ret_split_lines5_v0[@]}")
    return 0
}

# Runs `cmd`, and on failure records `what` and carries on.
# step(what: Text, cmd: Text)
step__179_v0() {
    local what_456="${1}"
    local cmd_457="${2}"
    run__174_v0 "${cmd_457}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        note_problem__177_v0 "${what_456} failed: ${cmd_457}"
    fi
}

# Which OS and package managers this machine has.
# "mac", "debian", "arch", "linux" (another distribution) or "unknown".
# os_from(ostype: Text, debian_version: Bool, arch_release: Bool)
os_from__194_v0() {
    local ostype_90="${1}"
    local debian_version_91="${2}"
    local arch_release_92="${3}"
    starts_with__22_v0 "${ostype_90}" "darwin"
    local ret_starts_with22_v0__9_8="${ret_starts_with22_v0}"
    if [ "${ret_starts_with22_v0__9_8}" != 0 ]; then
        ret_os_from194_v0="mac"
        return 0
    fi
    starts_with__22_v0 "${ostype_90}" "linux"
    local ret_starts_with22_v0__12_12="${ret_starts_with22_v0}"
    if [ "$(( ! ret_starts_with22_v0__12_12 ))" != 0 ]; then
        ret_os_from194_v0="unknown"
        return 0
    fi
    if [ "${debian_version_91}" != 0 ]; then
        ret_os_from194_v0="debian"
        return 0
    fi
    if [ "${arch_release_92}" != 0 ]; then
        ret_os_from194_v0="arch"
        return 0
    fi
    ret_os_from194_v0="linux"
    return 0
}

# os()
os__195_v0() {
    # $OSTYPE is a bash variable, not exported, so ask the running shell.
    local command_22
    command_22="$(printf '%s' "$OSTYPE")"
    __status=$?
    local ostype_89="${command_22}"
    file_exists__39_v0 "/etc/debian_version"
    local ret_file_exists39_v0__27_28="${ret_file_exists39_v0}"
    file_exists__39_v0 "/etc/arch-release"
    local ret_file_exists39_v0__27_64="${ret_file_exists39_v0}"
    os_from__194_v0 "${ostype_89}" "${ret_file_exists39_v0__27_28}" "${ret_file_exists39_v0__27_64}"
    ret_os195_v0="${ret_os_from194_v0}"
    return 0
}

# The AUR helper, in order of preference: "pamac" (Manjaro), "paru", "yay",
# or "" for none.
# USB vendors of the fingerprint readers libfprint supports: Synaptics, Goodix,
# Validity, Elan, FPC, Egis, FocalTech, Upek, AuthenTec. Elan also makes
# touchscreens, so a false positive just installs an unused fprintd.
# Command-line arguments.
# What the arguments ask for: "run", "dry-run", "help", or "bad" for anything
# else. args[0] is the script itself.
# 
# No `continue` here: in `for i, x in ...` amber increments i at the end of the
# body, so `continue` skips the increment and the loop never moves past i == 0.
# parse_mode(args: [Text])
parse_mode__200_v0() {
    local args_32=("${!1}")
    local mode_33="run"
    i_35=0;
    for arg_34 in "${args_32[@]}"; do
        if [ "$(( i_35 > 0 ))" != 0 ]; then
            if [ "$(( $([ "_${arg_34}" != "_--dry-run" ]; echo $?) || $([ "_${arg_34}" != "_-n" ]; echo $?) ))" != 0 ]; then
                if [ "$([ "_${mode_33}" != "_run" ]; echo $?)" != 0 ]; then
                    mode_33="dry-run"
                fi
            elif [ "$(( $([ "_${arg_34}" != "_--help" ]; echo $?) || $([ "_${arg_34}" != "_-h" ]; echo $?) ))" != 0 ]; then
                ret_parse_mode200_v0="help"
                return 0
            else
                ret_parse_mode200_v0="bad"
                return 0
            fi
        fi
        (( i_35++ )) || true
    done
    ret_parse_mode200_v0="${mode_33}"
    return 0
}

# Every change the installer makes to the machine goes through run(), so
# --dry-run can print the whole sequence instead. Read-only probes (is a
# program installed, does a unit exist) run directly.
# 
# The dry-run flag and the list of problems live in exported variables and a
# file, not in module variables: amber compiles a module once per import path
# ("./src/run.ab" from main.ab, "./run.ab" from src/links.ab), and each copy
# would get its own variables.
# Call once, first thing in main: it also clears a flag inherited from the
# environment and starts an empty problem list.
# is_dry_run()
is_dry_run__208_v0() {
    env_var_get__120_v0 "INSTALL_DRY_RUN"
    __status=$?
    local ret_env_var_get120_v0__27_18="${ret_env_var_get120_v0}"
    ret_is_dry_run208_v0="$([ "_${ret_env_var_get120_v0__27_18}" != "_1" ]; echo $?)"
    return 0
}

# `text` as one shell word, safe to splice into a command line.
# quoted(text: Text)
quoted__209_v0() {
    local text_148="${1}"
    local command_26
    command_26="$(printf '%q' "${text_148}")"
    __status=$?
    ret_quoted209_v0="${command_26}"
    return 0
}

# "sudo " unless already root.
# root_prefix(root: Bool)
root_prefix__210_v0() {
    local root_263="${1}"
    if [ "${root_263}" != 0 ]; then
        ret_root_prefix210_v0=""
        return 0
    fi
    ret_root_prefix210_v0="sudo "
    return 0
}

# `cmd` run as root: through sudo, or directly when the installer is root.
# as_root(cmd: Text)
as_root__211_v0() {
    local cmd_314="${1}"
    is_root__127_v0 
    local ret_is_root127_v0__45_24="${ret_is_root127_v0}"
    root_prefix__210_v0 "${ret_is_root127_v0__45_24}"
    local ret_root_prefix210_v0__45_12="${ret_root_prefix210_v0}"
    ret_as_root211_v0="${ret_root_prefix210_v0__45_12}""${cmd_314}"
    return 0
}

# Runs a shell command line (in this shell, so `source` and `export` stick).
# run(cmd: Text)
run__212_v0() {
    local cmd_142="${1}"
    is_dry_run__208_v0 
    local ret_is_dry_run208_v0__50_8="${ret_is_dry_run208_v0}"
    if [ "${ret_is_dry_run208_v0__50_8}" != 0 ]; then
        echo "[dry-run] ${cmd_142}"
        ret_run212_v0=''
        return 0
    fi
    eval "${cmd_142}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_run212_v0=''
        return "${__status}"
    fi
}

# heading(text: Text)
heading__213_v0() {
    local text_138="${1}"
    printf '%s\n' ""
    printf '\033[1;34m==> %s\033[0m
' "${text_138}"
    __status=$?
}

# warn(text: Text)
warn__214_v0() {
    local text_144="${1}"
    printf '\033[1;33mwarning:\033[0m %s
' "${text_144}" >&2
    __status=$?
}

# Problems the run carried on past, reported together at the end.
# note_problem(text: Text)
note_problem__215_v0() {
    local text_143="${1}"
    warn__214_v0 "${text_143}"
    env_var_get__120_v0 "INSTALL_PROBLEMS_FILE"
    __status=$?
    local problems_file_145="${ret_env_var_get120_v0}"
    if [ "$([ "_${problems_file_145}" == "_" ]; echo $?)" != 0 ]; then
        file_append__42_v0 "${problems_file_145}" "${text_143}"
        __status=$?
    fi
}

# Runs `cmd`, and on failure records `what` and carries on.
# step(what: Text, cmd: Text)
step__217_v0() {
    local what_140="${1}"
    local cmd_141="${2}"
    run__212_v0 "${cmd_141}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        note_problem__215_v0 "${what_140} failed: ${cmd_141}"
    fi
}

# Which OS and package managers this machine has.
# "mac", "debian", "arch", "linux" (another distribution) or "unknown".
# os_from(ostype: Text, debian_version: Bool, arch_release: Bool)
os_from__230_v0() {
    local ostype_253="${1}"
    local debian_version_254="${2}"
    local arch_release_255="${3}"
    starts_with__22_v0 "${ostype_253}" "darwin"
    local ret_starts_with22_v0__9_8="${ret_starts_with22_v0}"
    if [ "${ret_starts_with22_v0__9_8}" != 0 ]; then
        ret_os_from230_v0="mac"
        return 0
    fi
    starts_with__22_v0 "${ostype_253}" "linux"
    local ret_starts_with22_v0__12_12="${ret_starts_with22_v0}"
    if [ "$(( ! ret_starts_with22_v0__12_12 ))" != 0 ]; then
        ret_os_from230_v0="unknown"
        return 0
    fi
    if [ "${debian_version_254}" != 0 ]; then
        ret_os_from230_v0="debian"
        return 0
    fi
    if [ "${arch_release_255}" != 0 ]; then
        ret_os_from230_v0="arch"
        return 0
    fi
    ret_os_from230_v0="linux"
    return 0
}

# os()
os__231_v0() {
    # $OSTYPE is a bash variable, not exported, so ask the running shell.
    local command_27
    command_27="$(printf '%s' "$OSTYPE")"
    __status=$?
    local ostype_252="${command_27}"
    file_exists__39_v0 "/etc/debian_version"
    local ret_file_exists39_v0__27_28="${ret_file_exists39_v0}"
    file_exists__39_v0 "/etc/arch-release"
    local ret_file_exists39_v0__27_64="${ret_file_exists39_v0}"
    os_from__230_v0 "${ostype_252}" "${ret_file_exists39_v0__27_28}" "${ret_file_exists39_v0__27_64}"
    ret_os231_v0="${ret_os_from230_v0}"
    return 0
}

# The AUR helper, in order of preference: "pamac" (Manjaro), "paru", "yay",
# or "" for none.
# aur_helper()
aur_helper__232_v0() {
    local array_30=("pamac" "paru" "yay")
    for helper_257 in "${array_30[@]}"; do
        is_command__122_v0 "${helper_257}"
        local ret_is_command122_v0__34_12="${ret_is_command122_v0}"
        if [ "${ret_is_command122_v0__34_12}" != 0 ]; then
            ret_aur_helper232_v0="${helper_257}"
            return 0
        fi
    done
    ret_aur_helper232_v0=""
    return 0
}

# USB vendors of the fingerprint readers libfprint supports: Synaptics, Goodix,
# Validity, Elan, FPC, Egis, FocalTech, Upek, AuthenTec. Elan also makes
# touchscreens, so a false positive just installs an unused fprintd.
__FINGERPRINT_VENDORS_4=("06cb" "27c6" "138a" "04f3" "10a5" "1c7a" "2808" "147e" "08ff")
# is_fingerprint_vendor(id: Text)
is_fingerprint_vendor__233_v0() {
    local id_283="${1}"
    for vendor_284 in "${__FINGERPRINT_VENDORS_4[@]}"; do
        trim__10_v0 "${id_283}"
        local ret_trim10_v0__48_12="${ret_trim10_v0}"
        if [ "$([ "_${ret_trim10_v0__48_12}" != "_${vendor_284}" ]; echo $?)" != 0 ]; then
            ret_is_fingerprint_vendor233_v0=1
            return 0
        fi
    done
    ret_is_fingerprint_vendor233_v0=0
    return 0
}

# has_fingerprint_reader()
has_fingerprint_reader__234_v0() {
    file_glob__50_v0 "/sys/bus/usb/devices/*/idVendor"
    local ret_file_glob50_v0__56_17=("${ret_file_glob50_v0[@]}")
    for path_282 in "${ret_file_glob50_v0__56_17[@]}"; do
        local command_36
        command_36="$(cat "${path_282}" 2>/dev/null)"
        __status=$?
        is_fingerprint_vendor__233_v0 "${command_36}"
        local ret_is_fingerprint_vendor233_v0__57_12="${ret_is_fingerprint_vendor233_v0}"
        if [ "${ret_is_fingerprint_vendor233_v0__57_12}" != 0 ]; then
            ret_has_fingerprint_reader234_v0=1
            return 0
        fi
    done
    ret_has_fingerprint_reader234_v0=0
    return 0
}

# What the installer puts on each platform. Names were checked against the Arch
# repositories, the AUR and Debian stable (trixie) in September 2026: a package
# is in COMMON only when both call it the same thing.
# Arch and Debian, same name on both.
__COMMON_5=("asciinema" "bat" "bc" "chafa" "cmake" "coreutils" "cowsay" "curl" "eza" "fcitx5" "fcitx5-mozc" "fzf" "fzy" "git" "git-absorb" "gource" "gum" "imagemagick" "jq" "luajit" "luarocks" "make" "maven" "neovim" "ripgrep" "ruby" "rustup" "shellcheck" "starship" "tmux" "tree" "vim" "xclip" "zoxide" "zsh")
# Arch only, or with an Arch-specific name.
__ARCH_6=("code" "deno" "fd" "firefox" "geckodriver" "jdk-openjdk" "mise" "pandoc-cli" "rofimoji" "sqlite" "age" "alacritty" "awww" "bazelisk" "bitwarden" "bitwarden-cli" "cpio" "git-branchless" "github-cli" "hypridle" "hyprlock" "hyprsunset" "inotify-tools" "kdeconnect" "kio-gdrive" "meson" "neovide" "obsidian" "sops" "sshfs" "swayosd" "tlp" "tlpui" "fop" "glu" "libpng" "libxslt" "mesa" "unixodbc" "wxwidgets-gtk3")
# Only on Manjaro, where pamac is the package manager.
__MANJARO_7=("libpamac-flatpak-plugin" "libpamac-snap-plugin")
# From the AUR, through pamac, paru or yay.
__AUR_8=("amber-lang-bin" "changie" "hypr-persist" "l1p0-menus-git" "neovim-nightly" "pay-respects" "tmux-mem-cpu-load")
# Debian only, or with a Debian-specific name.
__DEBIAN_9=("default-jdk" "fd-find" "firefox-esr" "pandoc" "sqlite3" "apt-file" "debian-handbook" "devscripts" "etherwake" "fortunes-debian-hints" "info" "libgraphicsmagick1-dev" "libmagickwand-dev" "net-tools" "texinfo" "wakeonlan")
# Package manager commands, and installing lists of packages with them.
# The system upgrade to run first, or "" when there is no package manager.
# paru and yay run as the user: they ask for sudo themselves and refuse to
# build AUR packages as root.
# update_command(os: Text, helper: Text, root: Bool)
update_command__240_v0() {
    local os_260="${1}"
    local helper_261="${2}"
    local root_262="${3}"
    root_prefix__210_v0 "${root_262}"
    local prefix_264="${ret_root_prefix210_v0}"
    if [ "$([ "_${os_260}" != "_debian" ]; echo $?)" != 0 ]; then
        ret_update_command240_v0="${prefix_264}apt update"
        return 0
    fi
    if [ "$([ "_${os_260}" == "_arch" ]; echo $?)" != 0 ]; then
        ret_update_command240_v0=""
        return 0
    fi
    if [ "$([ "_${helper_261}" != "_pamac" ]; echo $?)" != 0 ]; then
        ret_update_command240_v0="${prefix_264}pamac update --no-confirm"
        return 0
    elif [ "$(( $([ "_${helper_261}" != "_paru" ]; echo $?) || $([ "_${helper_261}" != "_yay" ]; echo $?) ))" != 0 ]; then
        ret_update_command240_v0="${helper_261} -Syu --noconfirm"
        return 0
    fi
    ret_update_command240_v0="${prefix_264}pacman -Syu --noconfirm"
    return 0
}

# The command that installs repository packages (append the names).
# install_command(os: Text, helper: Text, root: Bool)
install_command__241_v0() {
    local os_266="${1}"
    local helper_267="${2}"
    local root_268="${3}"
    root_prefix__210_v0 "${root_268}"
    local prefix_269="${ret_root_prefix210_v0}"
    if [ "$([ "_${os_266}" != "_debian" ]; echo $?)" != 0 ]; then
        ret_install_command241_v0="${prefix_269}apt install -y"
        return 0
    fi
    if [ "$([ "_${os_266}" == "_arch" ]; echo $?)" != 0 ]; then
        ret_install_command241_v0=""
        return 0
    fi
    if [ "$([ "_${helper_267}" != "_pamac" ]; echo $?)" != 0 ]; then
        ret_install_command241_v0="${prefix_269}pamac install --no-confirm"
        return 0
    elif [ "$(( $([ "_${helper_267}" != "_paru" ]; echo $?) || $([ "_${helper_267}" != "_yay" ]; echo $?) ))" != 0 ]; then
        ret_install_command241_v0="${helper_267} -S --needed --noconfirm"
        return 0
    fi
    ret_install_command241_v0="${prefix_269}pacman -S --needed --noconfirm"
    return 0
}

# The command that builds AUR packages, or "" without an AUR helper.
# aur_install_command(os: Text, helper: Text)
aur_install_command__242_v0() {
    local os_287="${1}"
    local helper_288="${2}"
    if [ "$([ "_${os_287}" == "_arch" ]; echo $?)" != 0 ]; then
        ret_aur_install_command242_v0=""
        return 0
    fi
    if [ "$([ "_${helper_288}" != "_pamac" ]; echo $?)" != 0 ]; then
        ret_aur_install_command242_v0="pamac build --no-confirm"
        return 0
    elif [ "$(( $([ "_${helper_288}" != "_paru" ]; echo $?) || $([ "_${helper_288}" != "_yay" ]; echo $?) ))" != 0 ]; then
        ret_aur_install_command242_v0="${helper_288} -S --needed --noconfirm"
        return 0
    fi
    ret_aur_install_command242_v0=""
    return 0
}

# The repository packages for `os`, shared ones first.
# platform_packages(os: Text, pamac: Bool)
platform_packages__243_v0() {
    local os_271="${1}"
    local pamac_272="${2}"
    if [ "$([ "_${os_271}" != "_debian" ]; echo $?)" != 0 ]; then
        ret_platform_packages243_v0=("${__COMMON_5[@]}" "${__DEBIAN_9[@]}")
        return 0
    fi
    if [ "$([ "_${os_271}" != "_arch" ]; echo $?)" != 0 ]; then
        if [ "${pamac_272}" != 0 ]; then
            local array_add_43=("${__COMMON_5[@]}" "${__ARCH_6[@]}")
            ret_platform_packages243_v0=("${array_add_43[@]}" "${__MANJARO_7[@]}")
            return 0
        fi
        ret_platform_packages243_v0=("${__COMMON_5[@]}" "${__ARCH_6[@]}")
        return 0
    fi
    ret_platform_packages243_v0=()
    return 0
}

# Installs one package at a time so one bad name does not stop the rest.
# Returns the ones that failed.
# install_each(cmd: Text, packages: [Text])
install_each__244_v0() {
    local cmd_273="${1}"
    local packages_274=("${!2}")
    local failed_packages_275=()
    for package_276 in "${packages_274[@]}"; do
        echo "Installing ${package_276}"
        run__212_v0 "${cmd_273} ${package_276}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            failed_packages_275+=("${package_276}")
        fi
    done
    ret_install_each244_v0=("${failed_packages_275[@]}")
    return 0
}

# install_linux_packages()
install_linux_packages__245_v0() {
    os__231_v0 
    local this_os_256="${ret_os231_v0}"
    aur_helper__232_v0 
    local helper_258="${ret_aur_helper232_v0}"
    is_root__127_v0 
    local root_259="${ret_is_root127_v0}"
    update_command__240_v0 "${this_os_256}" "${helper_258}" "${root_259}"
    local update_265="${ret_update_command240_v0}"
    install_command__241_v0 "${this_os_256}" "${helper_258}" "${root_259}"
    local install_270="${ret_install_command241_v0}"
    if [ "$([ "_${install_270}" != "_" ]; echo $?)" != 0 ]; then
        warn__214_v0 "no supported package manager on this Linux (${this_os_256}); skipping packages"
        ret_install_linux_packages245_v0=''
        return 0
    fi
    heading__213_v0 "Updating the system"
    run__212_v0 "${update_265}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        note_problem__215_v0 "system update failed: ${update_265}"
    fi
    heading__213_v0 "Installing packages with: ${install_270}"
    platform_packages__243_v0 "${this_os_256}" "$([ "_${helper_258}" != "_pamac" ]; echo $?)"
    local ret_platform_packages243_v0__100_49=("${ret_platform_packages243_v0[@]}")
    install_each__244_v0 "${install_270}" ret_platform_packages243_v0__100_49[@]
    local failed_packages_277=("${ret_install_each244_v0[@]}")
    # fprintd for hyprlock's fingerprint unlock (.config/hypr/hyprlock.conf),
    # only where there is a reader. Enroll from the SUPER+SHIFT+R menu after.
    has_fingerprint_reader__234_v0 
    local ret_has_fingerprint_reader234_v0__104_8="${ret_has_fingerprint_reader234_v0}"
    if [ "${ret_has_fingerprint_reader234_v0__104_8}" != 0 ]; then
        echo "Fingerprint reader found"
        local array_51=("fprintd")
        install_each__244_v0 "${install_270}" array_51[@]
        failed_packages_277+=("${ret_install_each244_v0[@]}")
    fi
    aur_install_command__242_v0 "${this_os_256}" "${helper_258}"
    local aur_289="${ret_aur_install_command242_v0}"
    if [ "$([ "_${this_os_256}" != "_arch" ]; echo $?)" != 0 ]; then
        if [ "$([ "_${aur_289}" != "_" ]; echo $?)" != 0 ]; then
            join__7_v0 __AUR_8[@] " "
            local ret_join7_v0__112_72="${ret_join7_v0}"
            note_problem__215_v0 "no AUR helper (pamac, paru or yay); skipped ${ret_join7_v0__112_72}"
        else
            heading__213_v0 "Installing AUR packages with: ${aur_289}"
            install_each__244_v0 "${aur_289}" __AUR_8[@]
            failed_packages_277+=("${ret_install_each244_v0[@]}")
        fi
    fi
    local __length_52=("${failed_packages_277[@]}")
    if [ "$(( ${#__length_52[@]} > 0 ))" != 0 ]; then
        join__7_v0 failed_packages_277[@] " "
        local ret_join7_v0__120_57="${ret_join7_v0}"
        note_problem__215_v0 "packages that failed to install: ${ret_join7_v0__120_57}"
    fi
}

# Symlinks from $HOME into the repo.
# Linked to the same path under $HOME, so ~/.config/nvim -> rcfiles/.config/nvim.
__HOME_LINKS_15=(".config/amp" ".config/ghostty" ".config/herdr" ".config/hypr" ".config/jj" ".config/l1p0-menu" ".config/nvim" ".config/swaync" ".config/swayosd" ".config/waybar" ".claude/agents" ".cowfiles" ".cowrc" ".gitconfig" ".golangci.yml" ".iex.exs" ".oh-my-zsh" ".tmux" ".tmux.conf" ".vim/colors" ".vimrc" ".zshrc" ".zshrc.githubcopilot" "zsh-custom" "zsh-my-completions")
# Created empty if missing: vim's backup and swap directories, the local vimrc.
__HOME_DIRS_16=(".vim/backupdir" ".vim/swapdir" ".local" ".config/systemd/user")
__HOME_FILES_17=(".vimrc.local")
# parent_dir(path: Text)
parent_dir__254_v0() {
    local path_369="${1}"
    split__4_v0 "${path_369}" "/"
    local parts_373=("${ret_split4_v0[@]}")
    local __length_56=("${parts_373[@]}")
    if [ "$(( ${#__length_56[@]} < 2 ))" != 0 ]; then
        ret_parent_dir254_v0="."
        return 0
    fi
    local parent_374=()
    i_376=0;
    for part_375 in "${parts_373[@]}"; do
        local __length_60=("${parts_373[@]}")
        if [ "$(( i_376 < $(( ${#__length_60[@]} - 1 )) ))" != 0 ]; then
            parent_374+=("${part_375}")
        fi
        (( i_376++ )) || true
    done
    join__7_v0 parent_374[@] "/"
    ret_parent_dir254_v0="${ret_join7_v0}"
    return 0
}

# is_symlink(path: Text)
is_symlink__255_v0() {
    local path_368="${1}"
    test -L "${path_368}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_is_symlink255_v0=0
        return 0
    fi
    ret_is_symlink255_v0=1
    return 0
}

# ln -sfn would put the link inside a real directory rather than replace it,
# so a real directory in the way is reported and left alone.
# link(source: Text, destination: Text)
link__256_v0() {
    local source_366="${1}"
    local destination_367="${2}"
    dir_exists__38_v0 "${destination_367}"
    local ret_dir_exists38_v0__64_8="${ret_dir_exists38_v0}"
    is_symlink__255_v0 "${destination_367}"
    local ret_is_symlink255_v0__64_40="${ret_is_symlink255_v0}"
    if [ "$(( ret_dir_exists38_v0__64_8 && $(( ! ret_is_symlink255_v0__64_40 )) ))" != 0 ]; then
        note_problem__215_v0 "${destination_367} is a real directory, not linking it to ${source_366}"
        ret_link256_v0=''
        return 0
    fi
    parent_dir__254_v0 "${destination_367}"
    local ret_parent_dir254_v0__68_27="${ret_parent_dir254_v0}"
    quoted__209_v0 "${ret_parent_dir254_v0__68_27}"
    local ret_quoted209_v0__68_20="${ret_quoted209_v0}"
    quoted__209_v0 "${source_366}"
    local ret_quoted209_v0__68_65="${ret_quoted209_v0}"
    quoted__209_v0 "${destination_367}"
    local ret_quoted209_v0__68_82="${ret_quoted209_v0}"
    run__212_v0 "mkdir -p ${ret_quoted209_v0__68_20} && ln -sfn ${ret_quoted209_v0__68_65} ${ret_quoted209_v0__68_82}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        note_problem__215_v0 "could not link ${destination_367}"
    fi
}

# link_home(rc_dir: Text, home: Text)
link_home__257_v0() {
    local rc_dir_361="${1}"
    local home_362="${2}"
    for dir_363 in "${__HOME_DIRS_16[@]}"; do
        quoted__209_v0 "${home_362}/${dir_363}"
        local ret_quoted209_v0__75_24="${ret_quoted209_v0}"
        run__212_v0 "mkdir -p ${ret_quoted209_v0__75_24}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            note_problem__215_v0 "could not create ${home_362}/${dir_363}"
        fi
    done
    for file_364 in "${__HOME_FILES_17[@]}"; do
        quoted__209_v0 "${home_362}/${file_364}"
        local ret_quoted209_v0__80_21="${ret_quoted209_v0}"
        run__212_v0 "touch ${ret_quoted209_v0__80_21}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            note_problem__215_v0 "could not create ${home_362}/${file_364}"
        fi
    done
    for entry_365 in "${__HOME_LINKS_15[@]}"; do
        link__256_v0 "${rc_dir_361}/${entry_365}" "${home_362}/${entry_365}"
    done
}

# User units are linked one by one: ~/.config/systemd/user also holds local ones.
# link_systemd_units(rc_dir: Text, home: Text)
link_systemd_units__258_v0() {
    local rc_dir_381="${1}"
    local home_382="${2}"
    file_glob__50_v0 "${rc_dir_381}/.config/systemd/user/*"
    local ret_file_glob50_v0__91_17=("${ret_file_glob50_v0[@]}")
    for unit_383 in "${ret_file_glob50_v0__91_17[@]}"; do
        local command_70
        command_70="$(basename "${unit_383}")"
        __status=$?
        local name_384="${command_70}"
        link__256_v0 "${unit_383}" "${home_382}/.config/systemd/user/${name_384}"
    done
}

# systemd units the desktop relies on.
# unit_exists(unit: Text, user: Bool)
unit_exists__265_v0() {
    local unit_439="${1}"
    local user_440="${2}"
    local scope_441=""
    if [ "${user_440}" != 0 ]; then
        scope_441="--user "
    fi
    systemctl ${scope_441}cat ${unit_439} >/dev/null 2>&1
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_unit_exists265_v0=0
        return 0
    fi
    ret_unit_exists265_v0=1
    return 0
}

# setup_systemd()
setup_systemd__266_v0() {
    is_command__122_v0 "systemctl"
    local ret_is_command122_v0__18_12="${ret_is_command122_v0}"
    if [ "$(( ! ret_is_command122_v0__18_12 ))" != 0 ]; then
        ret_setup_systemd266_v0=''
        return 0
    fi
    # Pick up the user units link_systemd_units just linked.
    run__212_v0 "systemctl --user daemon-reload"
    __status=$?
    if [ "${__status}" != 0 ]; then
        note_problem__215_v0 "systemctl --user daemon-reload failed"
    fi
    # Hyprland starts swaync itself; stop D-Bus activating a second copy.
    run__212_v0 "systemctl --user mask swaync.service"
    __status=$?
    if [ "${__status}" != 0 ]; then
        note_problem__215_v0 "could not mask swaync.service"
    fi
    # ydotoold sends the notification center's vim keys (.config/hypr/conf/notifications.lua).
    unit_exists__265_v0 "ydotool.service" 1
    local ret_unit_exists265_v0__30_8="${ret_unit_exists265_v0}"
    if [ "${ret_unit_exists265_v0__30_8}" != 0 ]; then
        run__212_v0 "systemctl --user enable --now ydotool.service"
        __status=$?
        if [ "${__status}" != 0 ]; then
            note_problem__215_v0 "could not enable ydotool.service"
        fi
    fi
    # SwayOSD's key listener is a system service (it reads /dev/input as
    # root); swayosd-server itself is started by Hyprland.
    unit_exists__265_v0 "swayosd-libinput-backend.service" 0
    local ret_unit_exists265_v0__37_8="${ret_unit_exists265_v0}"
    if [ "${ret_unit_exists265_v0__37_8}" != 0 ]; then
        as_root__211_v0 "systemctl enable --now swayosd-libinput-backend.service"
        local ret_as_root211_v0__38_13="${ret_as_root211_v0}"
        run__212_v0 "${ret_as_root211_v0__38_13}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            note_problem__215_v0 "could not enable swayosd-libinput-backend.service"
        fi
    fi
}

# Symlinks from $HOME into the repo.
# Linked to the same path under $HOME, so ~/.config/nvim -> rcfiles/.config/nvim.
# Created empty if missing: vim's backup and swap directories, the local vimrc.
# parent_dir(path: Text)
parent_dir__279_v0() {
    local path_425="${1}"
    split__4_v0 "${path_425}" "/"
    local parts_426=("${ret_split4_v0[@]}")
    local __length_74=("${parts_426[@]}")
    if [ "$(( ${#__length_74[@]} < 2 ))" != 0 ]; then
        ret_parent_dir279_v0="."
        return 0
    fi
    local parent_427=()
    i_429=0;
    for part_428 in "${parts_426[@]}"; do
        local __length_78=("${parts_426[@]}")
        if [ "$(( i_429 < $(( ${#__length_78[@]} - 1 )) ))" != 0 ]; then
            parent_427+=("${part_428}")
        fi
        (( i_429++ )) || true
    done
    join__7_v0 parent_427[@] "/"
    ret_parent_dir279_v0="${ret_join7_v0}"
    return 0
}

# is_symlink(path: Text)
is_symlink__280_v0() {
    local path_419="${1}"
    test -L "${path_419}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_is_symlink280_v0=0
        return 0
    fi
    ret_is_symlink280_v0=1
    return 0
}

# ln -sfn would put the link inside a real directory rather than replace it,
# so a real directory in the way is reported and left alone.
# link(source: Text, destination: Text)
link__281_v0() {
    local source_423="${1}"
    local destination_424="${2}"
    dir_exists__38_v0 "${destination_424}"
    local ret_dir_exists38_v0__64_8="${ret_dir_exists38_v0}"
    is_symlink__280_v0 "${destination_424}"
    local ret_is_symlink280_v0__64_40="${ret_is_symlink280_v0}"
    if [ "$(( ret_dir_exists38_v0__64_8 && $(( ! ret_is_symlink280_v0__64_40 )) ))" != 0 ]; then
        note_problem__215_v0 "${destination_424} is a real directory, not linking it to ${source_423}"
        ret_link281_v0=''
        return 0
    fi
    parent_dir__279_v0 "${destination_424}"
    local ret_parent_dir279_v0__68_27="${ret_parent_dir279_v0}"
    quoted__209_v0 "${ret_parent_dir279_v0__68_27}"
    local ret_quoted209_v0__68_20="${ret_quoted209_v0}"
    quoted__209_v0 "${source_423}"
    local ret_quoted209_v0__68_65="${ret_quoted209_v0}"
    quoted__209_v0 "${destination_424}"
    local ret_quoted209_v0__68_82="${ret_quoted209_v0}"
    run__212_v0 "mkdir -p ${ret_quoted209_v0__68_20} && ln -sfn ${ret_quoted209_v0__68_65} ${ret_quoted209_v0__68_82}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        note_problem__215_v0 "could not link ${destination_424}"
    fi
}

# User units are linked one by one: ~/.config/systemd/user also holds local ones.
# Claude Code settings: the tracked layer in the repo, the local one in $HOME.
# The fields of ~/.claude/settings.json that are this machine's own.
__LOCAL_FIELDS_21="{model, modelSettings, skipAutoPermissionPrompt, hooks, autoMode} | with_entries(select(.value "'!'"= null))"
# Claude Code writes the selected model and other machine state to
# ~/.claude/settings.json, so that file stays local and the tracked settings
# are linked beside it as settings.shared.json (the claude alias loads them).
# An old install linked settings.json itself into the repo: that link becomes
# a local file holding only the local fields.
# setup_claude(rc_dir: Text, home: Text)
setup_claude__286_v0() {
    local rc_dir_415="${1}"
    local home_416="${2}"
    local shared_417="${rc_dir_415}/.claude/settings.json"
    local local_settings_418="${home_416}/.claude/settings.json"
    is_symlink__280_v0 "${local_settings_418}"
    local is_link_420="${ret_is_symlink280_v0}"
    local command_80
    command_80="$(realpath "${local_settings_418}" 2>/dev/null)"
    __status=$?
    local target_421="${command_80}"
    quoted__209_v0 "${local_settings_418}.tmp"
    local tmp_422="${ret_quoted209_v0}"
    file_exists__39_v0 "${local_settings_418}"
    local ret_file_exists39_v0__28_13="${ret_file_exists39_v0}"
    if [ "$(( is_link_420 && $([ "_${target_421}" != "_${shared_417}" ]; echo $?) ))" != 0 ]; then
        quoted__209_v0 "${__LOCAL_FIELDS_21}"
        local ret_quoted209_v0__24_22="${ret_quoted209_v0}"
        quoted__209_v0 "${local_settings_418}"
        local ret_quoted209_v0__24_45="${ret_quoted209_v0}"
        quoted__209_v0 "${local_settings_418}"
        local ret_quoted209_v0__24_92="${ret_quoted209_v0}"
        run__212_v0 "jq ${ret_quoted209_v0__24_22} ${ret_quoted209_v0__24_45} >${tmp_422} && mv -f ${tmp_422} ${ret_quoted209_v0__24_92}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            note_problem__215_v0 "could not migrate ${local_settings_418}"
        fi
    elif [ "$(( $(( ! ret_file_exists39_v0__28_13 )) && $(( ! is_link_420 )) ))" != 0 ]; then
        quoted__209_v0 "${home_416}/.claude"
        local ret_quoted209_v0__29_28="${ret_quoted209_v0}"
        quoted__209_v0 "${local_settings_418}"
        local ret_quoted209_v0__29_75="${ret_quoted209_v0}"
        run__212_v0 "mkdir -p ${ret_quoted209_v0__29_28} && printf '{}\\n' >${ret_quoted209_v0__29_75}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            note_problem__215_v0 "could not create ${local_settings_418}"
        fi
    fi
    link__281_v0 "${shared_417}" "${home_416}/.claude/settings.shared.json"
}

# Language toolchains: mise for most, cargo for Rust tools, mix for Elixir.
# Each step reports a failure and carries on, like the package installs.
# `mise use -g`, one line per tool so a bad version only loses that tool.
__MISE_GLOBALS_22=("node@latest" "deno@latest" "bun@latest" "pnpm@latest" "yarn@latest" "go@latest" "uv@latest" "erlang@28.0.2" "elixir@1.18.4-otp-28")
# cargo binstall downloads prebuilt binaries where it can.
__CARGO_BINSTALL_23=("mdcat" "bat" "git-delta" "tree-sitter-cli")
# Installed through cargo only when the system has no such program, e.g. on
# Debian, where these are not packaged.
__CARGO_IF_MISSING_CRATES_24=("fd-find" "git-branchless")
__CARGO_IF_MISSING_BINARIES_25=("fd" "git-branchless")
__MIX_ARCHIVES_26=("mix archive.install hex mix_templates" "mix archive.install hex mix_generator" "mix template.install hex gen_template_template" "mix template.install hex bpollack_elixir_template")
# install_mise_tools()
install_mise_tools__299_v0() {
    is_command__122_v0 "mise"
    local ret_is_command122_v0__37_12="${ret_is_command122_v0}"
    if [ "$(( ! ret_is_command122_v0__37_12 ))" != 0 ]; then
        note_problem__215_v0 "mise is not installed; skipped the mise tools"
        ret_install_mise_tools299_v0=''
        return 0
    fi
    for tool_312 in "${__MISE_GLOBALS_22[@]}"; do
        step__217_v0 "mise use -g ${tool_312}" "mise use -g ${tool_312}"
    done
}

# install_nix()
install_nix__300_v0() {
    # The installer refuses to run over an existing /nix.
    is_command__122_v0 "nix"
    local ret_is_command122_v0__48_8="${ret_is_command122_v0}"
    dir_exists__38_v0 "/nix"
    local ret_dir_exists38_v0__48_29="${ret_dir_exists38_v0}"
    if [ "$(( ret_is_command122_v0__48_8 || ret_dir_exists38_v0__48_29 ))" != 0 ]; then
        echo "nix is already installed"
        ret_install_nix300_v0=''
        return 0
    fi
    as_root__211_v0 "sh <(curl -L https://nixos.org/nix/install) --daemon"
    local ret_as_root211_v0__52_25="${ret_as_root211_v0}"
    step__217_v0 "nix install" "${ret_as_root211_v0__52_25}"
}

# install_rust_tools(home: Text)
install_rust_tools__301_v0() {
    local home_315="${1}"
    # rustup installs no toolchain by itself; cargo fails until there is one.
    is_command__122_v0 "rustup"
    local ret_is_command122_v0__57_8="${ret_is_command122_v0}"
    if [ "${ret_is_command122_v0__57_8}" != 0 ]; then
        rustup show active-toolchain >/dev/null 2>&1
        __status=$?
        if [ "${__status}" != 0 ]; then
            step__217_v0 "rustup default stable" "rustup default stable"
        fi
    fi
    file_exists__39_v0 "${home_315}/.cargo/env"
    local ret_file_exists39_v0__62_8="${ret_file_exists39_v0}"
    if [ "${ret_file_exists39_v0__62_8}" != 0 ]; then
        quoted__209_v0 "${home_315}/.cargo/env"
        local ret_quoted209_v0__63_17="${ret_quoted209_v0}"
        run__212_v0 ". ${ret_quoted209_v0__63_17}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            note_problem__215_v0 "could not source ${home_315}/.cargo/env"
        fi
    fi
    is_command__122_v0 "cargo"
    local ret_is_command122_v0__67_12="${ret_is_command122_v0}"
    is_dry_run__208_v0 
    local ret_is_dry_run208_v0__67_40="${ret_is_dry_run208_v0}"
    if [ "$(( $(( ! ret_is_command122_v0__67_12 )) && $(( ! ret_is_dry_run208_v0__67_40 )) ))" != 0 ]; then
        note_problem__215_v0 "cargo is not installed; skipped the Rust tools"
        ret_install_rust_tools301_v0=''
        return 0
    fi
    is_command__122_v0 "cargo-binstall"
    local ret_is_command122_v0__71_12="${ret_is_command122_v0}"
    if [ "$(( ! ret_is_command122_v0__71_12 ))" != 0 ]; then
        step__217_v0 "cargo-binstall" "cargo install cargo-binstall"
    fi
    is_command__122_v0 "cargo-outdated"
    local ret_is_command122_v0__74_12="${ret_is_command122_v0}"
    if [ "$(( ! ret_is_command122_v0__74_12 ))" != 0 ]; then
        step__217_v0 "cargo-outdated" "cargo install --locked cargo-outdated"
    fi
    for crate_316 in "${__CARGO_BINSTALL_23[@]}"; do
        step__217_v0 "cargo binstall ${crate_316}" "cargo binstall --no-confirm ${crate_316}"
    done
    i_318=0;
    for crate_317 in "${__CARGO_IF_MISSING_CRATES_24[@]}"; do
        is_command__122_v0 "${__CARGO_IF_MISSING_BINARIES_25[${i_318}]?"Index out of bounds (at scripts/installer/./src/toolchains.ab:81:53)"}"
        local ret_is_command122_v0__81_16="${ret_is_command122_v0}"
        if [ "$(( ! ret_is_command122_v0__81_16 ))" != 0 ]; then
            step__217_v0 "cargo binstall ${crate_317}" "cargo binstall --no-confirm ${crate_317}"
        fi
        (( i_318++ )) || true
    done
    is_command__122_v0 "neovide"
    local ret_is_command122_v0__85_12="${ret_is_command122_v0}"
    if [ "$(( ! ret_is_command122_v0__85_12 ))" != 0 ]; then
        step__217_v0 "neovide" "cargo install --git https://github.com/neovide/neovide"
    fi
}

# install_elixir_tools()
install_elixir_tools__302_v0() {
    is_command__122_v0 "mix"
    local ret_is_command122_v0__91_12="${ret_is_command122_v0}"
    is_dry_run__208_v0 
    local ret_is_dry_run208_v0__91_38="${ret_is_dry_run208_v0}"
    if [ "$(( $(( ! ret_is_command122_v0__91_12 )) && $(( ! ret_is_dry_run208_v0__91_38 )) ))" != 0 ]; then
        note_problem__215_v0 "mix is not on PATH; skipped the Elixir tools"
        ret_install_elixir_tools302_v0=''
        return 0
    fi
    for archive_319 in "${__MIX_ARCHIVES_26[@]}"; do
        step__217_v0 "${archive_319}" "yes | ${archive_319}"
    done
    step__217_v0 "rebar and hex" "mix do local.rebar --force, local.hex --force"
    step__217_v0 "livebook" "mix escript.install --force hex livebook"
}

# install_toolchains(home: Text)
install_toolchains__303_v0() {
    local home_311="${1}"
    heading__213_v0 "Toolchains (mise)"
    install_mise_tools__299_v0 
    heading__213_v0 "Nix"
    install_nix__300_v0 
    heading__213_v0 "Rust tools"
    install_rust_tools__301_v0 "${home_311}"
    heading__213_v0 "Elixir tools"
    # mise's shims put mix on PATH for this run.
    quoted__209_v0 "${home_311}/.local/share/mise/shims"
    local ret_quoted209_v0__111_29="${ret_quoted209_v0}"
    run__212_v0 "export PATH=${ret_quoted209_v0__111_29}:\"\$PATH\""
    __status=$?
    install_elixir_tools__302_v0 
}

# macOS packages, and the Hyprland plugins.
# setup_mac(rc_dir: Text)
setup_mac__312_v0() {
    local rc_dir_137="${1}"
    heading__213_v0 "Homebrew"
    is_command__122_v0 "brew"
    local ret_is_command122_v0__8_12="${ret_is_command122_v0}"
    if [ "$(( ! ret_is_command122_v0__8_12 ))" != 0 ]; then
        step__217_v0 "Homebrew install" "/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        run__212_v0 "export PATH=/opt/homebrew/bin:\"\$PATH\""
        __status=$?
    fi
    # The Brewfile lists every package, so there is no list here.
    quoted__209_v0 "${rc_dir_137}/Brewfile"
    local ret_quoted209_v0__13_46="${ret_quoted209_v0}"
    step__217_v0 "brew bundle" "brew bundle --file=${ret_quoted209_v0__13_46}"
}

# Hyprspace (SUPER+SHIFT+W overview) and hyprfocus (focus bump). hyprpm needs
# a running Hyprland; outside one, Hyprland installs them at its next start
# (ensure-plugins in .config/hypr/scripts/system.sh).
# install_hyprland_plugins(rc_dir: Text)
install_hyprland_plugins__313_v0() {
    local rc_dir_443="${1}"
    env_var_get__120_v0 "HYPRLAND_INSTANCE_SIGNATURE"
    __status=$?
    local ret_env_var_get120_v0__20_14="${ret_env_var_get120_v0}"
    if [ "$([ "_${ret_env_var_get120_v0__20_14}" != "_" ]; echo $?)" != 0 ]; then
        echo "Not in Hyprland: it installs its plugins when it next starts"
        ret_install_hyprland_plugins313_v0=''
        return 0
    fi
    heading__213_v0 "Hyprland plugins"
    quoted__209_v0 "${rc_dir_443}/.config/hypr/scripts/system.sh"
    local ret_quoted209_v0__25_11="${ret_quoted209_v0}"
    run__212_v0 "${ret_quoted209_v0__25_11} install-plugins"
    __status=$?
    if [ "${__status}" != 0 ]; then
        warn__214_v0 "Hyprland plugin install failed; retry with 'Install/update Hyprland plugins' in SUPER+SHIFT+R"
    fi
}

# Sets up a machine from this repo: packages, toolchains, links from $HOME into
# the repo, the Hyprland plugins, the secrets, and zsh as the login shell.
# 
# ./install.sh             do it
# ./install.sh --dry-run   print every command that changes something instead
# 
# Safe to run again. The repo root's install.sh is a symlink to this project's
# compiled output, scripts/installer/install.sh.
# The repo root: $0 resolves through the root's install.sh symlink to
# <root>/scripts/installer/install.sh.
# find_rc_dir(self: Text)
find_rc_dir__316_v0() {
    local self_67="${1}"
    local command_94
    command_94="$(dirname "$(dirname "$(dirname "$(realpath "${self_67}")")")")"
    __status=$?
    ret_find_rc_dir316_v0="${command_94}"
    return 0
}

# usage()
usage__317_v0() {
    echo "usage: ./install.sh [--dry-run]"
}

# set_login_shell()
set_login_shell__318_v0() {
    local command_95
    command_95="$(command -v zsh)"
    __status=$?
    local zsh_462="${command_95}"
    if [ "$([ "_${zsh_462}" != "_" ]; echo $?)" != 0 ]; then
        warn__176_v0 "zsh is not installed; login shell unchanged"
        ret_set_login_shell318_v0=''
        return 0
    fi
    env_var_get__120_v0 "USER"
    __status=$?
    local user_463="${ret_env_var_get120_v0}"
    # $SHELL is the login shell, not the one running this script.
    env_var_get__120_v0 "SHELL"
    __status=$?
    local ret_env_var_get120_v0__41_14="${ret_env_var_get120_v0}"
    if [ "$([ "_${ret_env_var_get120_v0__41_14}" != "_${zsh_462}" ]; echo $?)" != 0 ]; then
        echo "zsh is already the login shell"
        ret_set_login_shell318_v0=''
        return 0
    fi
    quoted__171_v0 "${zsh_462}"
    local ret_quoted171_v0__45_28="${ret_quoted171_v0}"
    quoted__171_v0 "${user_463}"
    local ret_quoted171_v0__45_42="${ret_quoted171_v0}"
    step__179_v0 "chsh" "chsh -s ${ret_quoted171_v0__45_28} ${ret_quoted171_v0__45_42}"
}

typeset -r args_27=("$0" "$@")
parse_mode__200_v0 args_27[@]
mode_36="${ret_parse_mode200_v0}"
if [ "$([ "_${mode_36}" != "_help" ]; echo $?)" != 0 ]; then
    usage__317_v0 
    exit 0
elif [ "$([ "_${mode_36}" != "_bad" ]; echo $?)" != 0 ]; then
    usage__317_v0 
    exit 2
fi
init_run_state__169_v0 "$([ "_${mode_36}" != "_dry-run" ]; echo $?)"
is_root__127_v0 
ret_is_root127_v0__62_8="${ret_is_root127_v0}"
is_dry_run__170_v0 
ret_is_dry_run170_v0__62_26="${ret_is_dry_run170_v0}"
if [ "$(( ret_is_root127_v0__62_8 && $(( ! ret_is_dry_run170_v0__62_26 )) ))" != 0 ]; then
    input_confirm__125_v0 "You are running this script as root. Are you sure you want to continue?" 0
    ret_input_confirm125_v0__63_16="${ret_input_confirm125_v0}"
    if [ "$(( ! ret_input_confirm125_v0__63_16 ))" != 0 ]; then
        echo "Exiting the script."
        exit 1
    fi
fi
env_var_get__120_v0 "HOME"
__status=$?
home_55="${ret_env_var_get120_v0}"
if [ "$([ "_${home_55}" != "_" ]; echo $?)" != 0 ]; then
    echo_error__138_v0 "install.sh: HOME is not set" 1
fi
find_rc_dir__316_v0 "${args_27[0]?"Index out of bounds (at scripts/installer/main.ab:73:37)"}"
rc_dir_68="${ret_find_rc_dir316_v0}"
file_exists__39_v0 "${rc_dir_68}/.zshrc"
ret_file_exists39_v0__74_12="${ret_file_exists39_v0}"
if [ "$(( ! ret_file_exists39_v0__74_12 ))" != 0 ]; then
    echo_error__138_v0 "install.sh: ${rc_dir_68} does not look like the rcfiles repo" 1
fi
env_var_get__120_v0 "USER"
__status=$?
user_71="${ret_env_var_get120_v0}"
echo "Executing install.sh for ${user_71}"
echo "Installing to home directory: ${home_55}"
echo "From: ${rc_dir_68}"
is_dry_run__170_v0 
ret_is_dry_run170_v0__81_8="${ret_is_dry_run170_v0}"
if [ "${ret_is_dry_run170_v0__81_8}" != 0 ]; then
    echo "Dry run: nothing below is executed"
fi
os__195_v0 
this_os_95="${ret_os195_v0}"
if [ "$([ "_${this_os_95}" != "_mac" ]; echo $?)" != 0 ]; then
    setup_mac__312_v0 "${rc_dir_68}"
elif [ "$([ "_${this_os_95}" != "_unknown" ]; echo $?)" != 0 ]; then
    command_97="$(printf '%s' "$OSTYPE")"
    __status=$?
    ostype_149="${command_97}"
    echo_error__138_v0 "install.sh: unknown OS: ${ostype_149}" 1
else
    install_linux_packages__245_v0 
fi
install_toolchains__303_v0 "${home_55}"
heading__175_v0 "Links from ${home_55}"
link_home__257_v0 "${rc_dir_68}" "${home_55}"
link_systemd_units__258_v0 "${rc_dir_68}" "${home_55}"
setup_claude__286_v0 "${rc_dir_68}" "${home_55}"
setup_systemd__266_v0 
install_hyprland_plugins__313_v0 "${rc_dir_68}"
# Secrets (*.sops.*): gives this machine an age key and, with the master
# password, adds it to the recipients. Its changes to the repo need committing.
heading__175_v0 "Secrets"
quoted__171_v0 "${rc_dir_68}/scripts/sops/sops-bootstrap.sh"
ret_quoted171_v0__108_9="${ret_quoted171_v0}"
run__174_v0 "${ret_quoted171_v0__108_9}"
__status=$?
if [ "${__status}" != 0 ]; then
    warn__176_v0 "sops-bootstrap.sh failed; run \`mise run sops-bootstrap\` once sops and age are installed"
fi
# The pre-commit hook rebuilds the Amber projects under scripts/.
heading__175_v0 "Git hooks"
quoted__171_v0 "${rc_dir_68}"
ret_quoted171_v0__114_32="${ret_quoted171_v0}"
step__179_v0 "git hooks" "git -C ${ret_quoted171_v0__114_32} config core.hooksPath .githooks"
heading__175_v0 "Login shell"
set_login_shell__318_v0 
printf '%s\n' ""
problems__178_v0 
found_474=("${ret_problems178_v0[@]}")
__length_98=("${found_474[@]}")
if [ "$(( ${#__length_98[@]} > 0 ))" != 0 ]; then
    warn__176_v0 "finished with problems:"
    for problem_475 in "${found_474[@]}"; do
        echo "  - ${problem_475}"
    done
    exit 1
fi
echo_success__136_v0 "install.sh: done"
