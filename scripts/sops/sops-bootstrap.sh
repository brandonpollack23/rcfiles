#!/usr/bin/env bash
# GENERATED from scripts/sops/main.ab by scripts/build.ab. Edit the .ab sources, then run: mise run build
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
# replace(source: Text, search: Text, replace: Text)
replace__0_v0() {
    local source_167="${1}"
    local search_168="${2}"
    local replace_169="${3}"
    # Here we use a command to avoid #646
    local result_170=""
    left_comp=("${EXEC_SHELL_VERSION[@]}")
    right_comp=(4 3)
    local comp
    comp="$(
        # Compare if left array >= right array
        len_comp="$( (( "${#left_comp[@]}" < "${#right_comp[@]}" )) && echo "${#left_comp[@]}"|| echo "${#right_comp[@]}")"
        for (( i=0; i<len_comp; i++ )); do
            left="${left_comp[i]?"Index out of bounds (at unknown)"}"
            right="${right_comp[i]?"Index out of bounds (at unknown)"}"
            if (( "${left}" > "${right}" )); then
                echo 1
                exit
            elif (( "${left}" < "${right}" )); then
                echo 0
                exit
            fi
        done
        (( "${#left_comp[@]}" == "${#right_comp[@]}" || "${#left_comp[@]}" > "${#right_comp[@]}" )) && echo 1 || echo 0
)"
    if [ "$(( $([ "_${EXEC_SHELL}" != "_ksh" ]; echo $?) || $(( $([ "_${EXEC_SHELL}" != "_bash" ]; echo $?) && comp )) ))" != 0 ]; then
        result_170="${source_167//"${search_168}"/"${replace_169}"}"
        __status=$?
    else
        result_170="${source_167//"${search_168}"/${replace_169}}"
        __status=$?
    fi
    ret_replace0_v0="${result_170}"
    return 0
}

__SED_VERSION_UNKNOWN_0=0
__SED_VERSION_GNU_1=1
__SED_VERSION_BUSYBOX_2=2
# sed_version()
sed_version__2_v0() {
    # We can't match against a word "GNU" because
    # alpine's busybox sed returns "This is not GNU sed version"
    re='Copyright.+Free Software Foundation'; [[ $(sed --version 2>/dev/null) =~ $re ]]
    __status=$?
    if [ "$(( __status == 0 ))" != 0 ]; then
        ret_sed_version2_v0="${__SED_VERSION_GNU_1}"
        return 0
    fi
    # On BSD single `sed` waits for stdin. We must use `sed --help` to avoid this.
    re='BusyBox'; [[ $(sed --help 2>&1) =~ $re ]]
    __status=$?
    if [ "$(( __status == 0 ))" != 0 ]; then
        ret_sed_version2_v0="${__SED_VERSION_BUSYBOX_2}"
        return 0
    fi
    ret_sed_version2_v0="${__SED_VERSION_UNKNOWN_0}"
    return 0
}

# split(text: Text, delimiter: Text)
split__4_v0() {
    local text_158="${1}"
    local delimiter_159="${2}"
    local result_160=()
    # zsh uses -A for array, bash uses -a, ksh is VERY bad at splitting anything
    if [ "$([ "_${EXEC_SHELL}" != "_zsh" ]; echo $?)" != 0 ]; then
        IFS="${delimiter_159}" read -rd '' -A result_160 < <(printf %s "$text_158")
        __status=$?
    elif [ "$([ "_${EXEC_SHELL}" != "_ksh" ]; echo $?)" != 0 ]; then
        if [ "$([ "_${delimiter_159}" != "_
" ]; echo $?)" != 0 ]; then
            while read -r -d $'\n'; do result_160+=("$REPLY"); done < <(echo "$text_158")
            __status=$?
        else
            IFS="${delimiter_159}" read -rd '' -a result_160 < <(printf %s "$text_158")
            __status=$?
        fi
    elif [ "$([ "_${EXEC_SHELL}" != "_bash" ]; echo $?)" != 0 ]; then
        IFS="${delimiter_159}" read -rd '' -a result_160 < <(printf %s "$text_158")
        __status=$?
    fi
    ret_split4_v0=("${result_160[@]}")
    return 0
}

# split_lines(text: Text)
split_lines__5_v0() {
    local text_157="${1}"
    split__4_v0 "${text_157}" "
"
    ret_split_lines5_v0=("${ret_split4_v0[@]}")
    return 0
}

# join(list: [Text], delimiter: Text)
join__7_v0() {
    local list_58=("${!1}")
    local delimiter_59="${2}"
    local command_2
    command_2="$(IFS="${delimiter_59}" ; printf "%s
" "${list_58[*]}")"
    __status=$?
    ret_join7_v0="${command_2}"
    return 0
}

# trim(text: Text)
trim__10_v0() {
    local text_230="${1}"
    local result_231=""
    result_231="${text_230#${text_230%%[![:space:]]*}}"
    __status=$?
    result_231="${result_231%${result_231##*[![:space:]]}}"
    __status=$?
    ret_trim10_v0="${result_231}"
    return 0
}

# text_contains(source: Text, search: Text)
text_contains__16_v0() {
    local source_179="${1}"
    local search_180="${2}"
    [[ "${source_179}" == *"${search_180}"* ]]
    __status=$?
    ret_text_contains16_v0="$(( __status == 0 ))"
    return 0
}

# match_regex(source: Text, search: Text, extended: Bool)
match_regex__19_v0() {
    local source_163="${1}"
    local search_164="${2}"
    local extended_165="${3}"
    sed_version__2_v0 
    local sed_version_166="${ret_sed_version2_v0}"
    replace__0_v0 "${search_164}" "/" "\\/"
    search_164="${ret_replace0_v0}"
    local output_171=""
    if [ "$(( $(( sed_version_166 == __SED_VERSION_GNU_1 )) || $(( sed_version_166 == __SED_VERSION_BUSYBOX_2 )) ))" != 0 ]; then
        # '\b' is supported but not in POSIX standards. Disable it
        replace__0_v0 "${search_164}" "\\b" "\\\\b"
        search_164="${ret_replace0_v0}"
    fi
    if [ "${extended_165}" != 0 ]; then
        # GNU sed versions 4.0 through 4.2 support extended regex syntax,
        # but only via the "-r" option
        if [ "$(( sed_version_166 == __SED_VERSION_GNU_1 ))" != 0 ]; then
            # '\b' is not in POSIX standards. Disable it
            replace__0_v0 "${search_164}" "\\b" "\\b"
            search_164="${ret_replace0_v0}"
            local command_3
            command_3="$(sed -r -ne "/${search_164}/p" <<<"${source_163}")"
            __status=$?
            output_171="${command_3}"
        else
            local command_4
            command_4="$(sed -E -ne "/${search_164}/p" <<<"${source_163}")"
            __status=$?
            output_171="${command_4}"
        fi
    else
        if [ "$(( $(( sed_version_166 == __SED_VERSION_GNU_1 )) || $(( sed_version_166 == __SED_VERSION_BUSYBOX_2 )) ))" != 0 ]; then
            # GNU Sed BRE handle \| as a metacharacter, but it is not POSIX standands. Disable it
            replace__0_v0 "${search_164}" "\\|" "|"
            search_164="${ret_replace0_v0}"
        fi
        local command_5
        command_5="$(sed -ne "/${search_164}/p" <<<"${source_163}")"
        __status=$?
        output_171="${command_5}"
    fi
    if [ "$([ "_${output_171}" == "_" ]; echo $?)" != 0 ]; then
        ret_match_regex19_v0=1
        return 0
    fi
    ret_match_regex19_v0=0
    return 0
}

# starts_with(text: Text, prefix: Text)
starts_with__22_v0() {
    local text_233="${1}"
    local prefix_234="${2}"
    [[ "${text_233}" == "${prefix_234}"* ]]
    __status=$?
    ret_starts_with22_v0="$(( __status == 0 ))"
    return 0
}

# ends_with(text: Text, suffix: Text)
ends_with__23_v0() {
    local text_235="${1}"
    local suffix_236="${2}"
    [[ "${text_235}" == *"${suffix_236}" ]]
    __status=$?
    ret_ends_with23_v0="$(( __status == 0 ))"
    return 0
}

# slice(text: Text, index: Int, length: Int)
slice__24_v0() {
    local text_238="${1}"
    local index_239="${2}"
    local length_240="${3}"
    local result_241=""
    if [ "$(( length_240 == 0 ))" != 0 ]; then
        local __length_6="${text_238}"
        length_240="$(( ${#__length_6} - index_239 ))"
    fi
    if [ "$(( length_240 <= 0 ))" != 0 ]; then
        ret_slice24_v0="${result_241}"
        return 0
    fi
    result_241="${text_238: ${index_239}: ${length_240}}"
    __status=$?
    ret_slice24_v0="${result_241}"
    return 0
}

# count_chars(text: Text)
count_chars__33_v0() {
    local text_237="${1}"
    local command_7
    command_7="$(printf "%s" "${text_237}" | wc -m | tr -d ' ')"
    __status=$?
    ret_count_chars33_v0="${command_7}"
    return 0
}

# file_exists(path: Text)
file_exists__39_v0() {
    local path_49="${1}"
    [ -f "${path_49}" ]
    __status=$?
    ret_file_exists39_v0="$(( __status == 0 ))"
    return 0
}

# file_read(path: Text)
file_read__40_v0() {
    local path_175="${1}"
    local command_8
    command_8="$(< "${path_175}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_file_read40_v0=''
        return "${__status}"
    fi
    ret_file_read40_v0="${command_8}"
    return 0
}

# file_write(path: Text, content: Text)
file_write__41_v0() {
    local path_68="${1}"
    local content_69="${2}"
    local command_9
    command_9="$(printf '%s
' "${content_69}" > "${path_68}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_file_write41_v0=''
        return "${__status}"
    fi
    ret_file_write41_v0="${command_9}"
    return 0
}

# env_var_get(name: Text)
env_var_get__120_v0() {
    local name_36="${1}"
    if [ "$([ "_${EXEC_SHELL}" != "_bash" ]; echo $?)" != 0 ]; then
        local command_10
        command_10="$(printf "%s
" "${!name_36}")"
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
" "${(P)name_36}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_env_var_get120_v0=''
            return "${__status}"
        fi
        ret_env_var_get120_v0="${command_11}"
        return 0
    elif [ "$([ "_${EXEC_SHELL}" != "_ksh" ]; echo $?)" != 0 ]; then
        local command_12
        command_12="$(eval "echo \${$name_36}")"
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
    local command_6="${1}"
    [ -x "$(command -v "${command_6}")" ]
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
    local format_15="${1}"
    local args_16=("${!2}")
    args_16=("${format_15}" "${args_16[@]}")
    __status=$?
    printf "${args_16[@]}"
    __status=$?
}

# echo_error(message: Text, exit_code: Int)
echo_error__138_v0() {
    local message_13="${1}"
    local exit_code_14="${2}"
    local array_13=("${message_13}")
    printf__128_v0 "\\x1b[1;3;97;41m%s\\x1b[0m
" array_13[@]
    if [ "$(( exit_code_14 > 0 ))" != 0 ]; then
        exit "${exit_code_14}"
    fi
}

# This machine's age key.
# Where sops looks for age keys: $SOPS_AGE_KEY_FILE, else
# ${XDG_CONFIG_HOME:-$HOME/.config}/sops/age/keys.txt.
# keys_path_from(sops_key_file: Text, xdg_config_home: Text, home: Text)
keys_path_from__165_v0() {
    local sops_key_file_37="${1}"
    local xdg_config_home_38="${2}"
    local home_39="${3}"
    if [ "$([ "_${sops_key_file_37}" == "_" ]; echo $?)" != 0 ]; then
        ret_keys_path_from165_v0="${sops_key_file_37}"
        return 0
    fi
    if [ "$([ "_${xdg_config_home_38}" == "_" ]; echo $?)" != 0 ]; then
        ret_keys_path_from165_v0="${xdg_config_home_38}/sops/age/keys.txt"
        return 0
    fi
    ret_keys_path_from165_v0="${home_39}/.config/sops/age/keys.txt"
    return 0
}

# keys_path()
keys_path__166_v0() {
    env_var_get__120_v0 "SOPS_AGE_KEY_FILE"
    __status=$?
    local ret_env_var_get120_v0__19_15="${ret_env_var_get120_v0}"
    env_var_get__120_v0 "XDG_CONFIG_HOME"
    __status=$?
    local ret_env_var_get120_v0__20_15="${ret_env_var_get120_v0}"
    env_var_get__120_v0 "HOME"
    __status=$?
    local ret_env_var_get120_v0__21_15="${ret_env_var_get120_v0}"
    keys_path_from__165_v0 "${ret_env_var_get120_v0__19_15}" "${ret_env_var_get120_v0__20_15}" "${ret_env_var_get120_v0__21_15}"
    ret_keys_path166_v0="${ret_keys_path_from165_v0}"
    return 0
}

# Creates the key file when it is missing or empty.
# ensure_machine_key(keys: Text)
ensure_machine_key__167_v0() {
    local keys_42="${1}"
    test -s "${keys_42}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo "Creating this machine's age key in ${keys_42}"
        mkdir -p "$(dirname "${keys_42}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_ensure_machine_key167_v0=''
            return "${__status}"
        fi
        age-keygen -o "${keys_42}" 2>/dev/null
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_ensure_machine_key167_v0=''
            return "${__status}"
        fi
        chmod 600 "${keys_42}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_ensure_machine_key167_v0=''
            return "${__status}"
        fi
    fi
}

# machine_public_key(keys: Text)
machine_public_key__168_v0() {
    local keys_44="${1}"
    local command_14
    command_14="$(age-keygen -y "${keys_44}" | head -n 1)"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_machine_public_key168_v0=''
        return "${__status}"
    fi
    ret_machine_public_key168_v0="${command_14}"
    return 0
}

# .sops.yaml, the list of keys every secret is encrypted to, and the secrets.
# Secrets are files named *.sops.<ext>, the same rule as in .sops.yaml.
# is_secret_file(path: Text)
is_secret_file__180_v0() {
    local path_162="${1}"
    match_regex__19_v0 "${path_162}" "[^/]\\.sops\\.(json|ya?ml|env|ini)\$" 1
    ret_is_secret_file180_v0="${ret_match_regex19_v0}"
    return 0
}

# Tracked and untracked (but not ignored) secret files, relative to the repo.
# secret_files(repo: Text)
secret_files__181_v0() {
    local repo_154="${1}"
    local found_155=()
    local command_16
    command_16="$(git -C "${repo_154}" ls-files --cached --others --exclude-standard)"
    __status=$?
    local listed_156="${command_16}"
    split_lines__5_v0 "${listed_156}"
    local ret_split_lines5_v0__14_17=("${ret_split_lines5_v0[@]}")
    for path_161 in "${ret_split_lines5_v0__14_17[@]}"; do
        is_secret_file__180_v0 "${path_161}"
        local ret_is_secret_file180_v0__15_12="${ret_is_secret_file180_v0}"
        if [ "${ret_is_secret_file180_v0__15_12}" != 0 ]; then
            found_155+=("${path_161}")
        fi
    done
    ret_secret_files181_v0=("${found_155[@]}")
    return 0
}

# .sops.yaml as the first run writes it, with only the master key.
# initial_rules(master: Text)
initial_rules__182_v0() {
    local master_57="${1}"
    local array_20=("# Secrets committed to this repo are files named *.sops.<ext>, encrypted to" "# every key below. scripts/sops/sops-bootstrap.sh (run by install.sh) maintains" "# this file: it adds each new machine, using the master key in" "# .sops-master.key.age, which the master password unlocks." "#" "# Recipients:" "#   ${master_57}  master" "creation_rules:" "  - path_regex: \\.sops\\.(json|ya?ml|env|ini)\$" "    age: >-" "      ${master_57}")
    join__7_v0 array_20[@] "
"
    ret_initial_rules182_v0="${ret_join7_v0}"
    return 0
}

# A line that is only indentation and an age key with no comma after it: the
# last recipient, which is always the master key.
# is_last_recipient(line: Text)
is_last_recipient__183_v0() {
    local line_229="${1}"
    trim__10_v0 "${line_229}"
    local key_232="${ret_trim10_v0}"
    starts_with__22_v0 "${key_232}" "age1"
    local ret_starts_with22_v0__43_12="${ret_starts_with22_v0}"
    ends_with__23_v0 "${key_232}" ","
    local ret_ends_with23_v0__43_45="${ret_ends_with23_v0}"
    ret_is_last_recipient183_v0="$(( ret_starts_with22_v0__43_12 && $(( ! ret_ends_with23_v0__43_45 )) ))"
    return 0
}

# Adds `key` to the rules: a comment line under "# Recipients:", and a
# recipient just above the master key so the master stays last and every
# other recipient ends in a comma.
# add_recipient(rules: Text, key: Text, label: Text)
add_recipient__184_v0() {
    local rules_224="${1}"
    local key_225="${2}"
    local label_226="${3}"
    local out_227=()
    split_lines__5_v0 "${rules_224}"
    local ret_split_lines5_v0__51_17=("${ret_split_lines5_v0[@]}")
    for line_228 in "${ret_split_lines5_v0__51_17[@]}"; do
        is_last_recipient__183_v0 "${line_228}"
        local ret_is_last_recipient183_v0__52_12="${ret_is_last_recipient183_v0}"
        if [ "${ret_is_last_recipient183_v0__52_12}" != 0 ]; then
            count_chars__33_v0 "${line_228}"
            local ret_count_chars33_v0__53_43="${ret_count_chars33_v0}"
            trim__10_v0 "${line_228}"
            local ret_trim10_v0__53_75="${ret_trim10_v0}"
            count_chars__33_v0 "${ret_trim10_v0__53_75}"
            local ret_count_chars33_v0__53_63="${ret_count_chars33_v0}"
            slice__24_v0 "${line_228}" 0 "$(( ret_count_chars33_v0__53_43 - ret_count_chars33_v0__53_63 ))"
            local indent_242="${ret_slice24_v0}"
            out_227+=("${indent_242}${key_225},")
        fi
        out_227+=("${line_228}")
        if [ "$([ "_${line_228}" != "_# Recipients:" ]; echo $?)" != 0 ]; then
            out_227+=("#   ${key_225}  ${label_226}")
        fi
    done
    join__7_v0 out_227[@] "
"
    ret_add_recipient184_v0="${ret_join7_v0}"
    return 0
}

# Lets this machine decrypt the repo's secrets (*.sops.*, rules in .sops.yaml).
# Run by install.sh and `mise run sops-bootstrap`; safe to run again, it only
# does what is still missing.
# 
# Every machine has its own age key in ~/.config/sops/age/keys.txt and is a
# recipient in .sops.yaml. What lets a new machine in is the master key: an age
# key that is also a recipient, committed as .sops-master.key.age, encrypted
# with a passphrase (the master password). So, on a new machine:
# 
# 1. make this machine's key, if it has none
# 2. add its public key to .sops.yaml
# 3. ask for the master password, and with the master key re-encrypt every
# secret to the new list of recipients (`sops updatekeys`)
# 
# after which the master key is not needed here again. Commit and push what
# changed (.sops.yaml and the secrets), or the next machine undoes it.
# 
# The first run anywhere creates the master key and asks for a new password.
# The repo root. This script lives two levels below it, in scripts/sops/.
# repo_root(self: Text)
repo_root__188_v0() {
    local self_20="${1}"
    local command_27
    command_27="$(dirname "$(realpath "${self_20}")")"
    __status=$?
    local here_21="${command_27}"
    local command_29
    command_29="$(git -C "${here_21}" rev-parse --show-toplevel 2>/dev/null)"
    __status=$?
    if [ "${__status}" != 0 ]; then
        local command_28
        command_28="$(realpath "${here_21}/../..")"
        __status=$?
        ret_repo_root188_v0="${command_28}"
        return 0
    fi
    local root_22="${command_29}"
    ret_repo_root188_v0="${root_22}"
    return 0
}

# file_write ends the file with a newline itself.
# write_rules(path: Text, rules: Text)
write_rules__189_v0() {
    local path_66="${1}"
    local rules_67="${2}"
    file_write__41_v0 "${path_66}" "${rules_67}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_write_rules189_v0=''
        return "${__status}"
    fi
}

typeset -r args_3=("$0" "$@")
array_33=("sops" "age" "age-keygen")
for tool_4 in "${array_33[@]}"; do
    is_command__122_v0 "${tool_4}"
    ret_is_command122_v0__42_16="${ret_is_command122_v0}"
    if [ "$(( ! ret_is_command122_v0__42_16 ))" != 0 ]; then
        echo_error__138_v0 "sops-bootstrap: ${tool_4} is not installed, skipping" 0
        exit 0
    fi
done
repo_root__188_v0 "${args_3[0]?"Index out of bounds (at scripts/sops/main.ab:48:33)"}"
repo_23="${ret_repo_root188_v0}"
rules_path_24="${repo_23}/.sops.yaml"
master_path_25="${repo_23}/.sops-master.key.age"
keys_path__166_v0 
keys_40="${ret_keys_path166_v0}"
ensure_machine_key__167_v0 "${keys_40}"
__status=$?
if [ "${__status}" != 0 ]; then
    exit "${__status}"
fi
machine_public_key__168_v0 "${keys_40}"
__status=$?
if [ "${__status}" != 0 ]; then
    exit "${__status}"
fi
machine_45="${ret_machine_public_key168_v0}"
command_34="$(uname -n)"
__status=$?
host_46="${command_34}"
rekey_with_machine_key_47=0
file_exists__39_v0 "${master_path_25}"
ret_file_exists39_v0__58_12="${ret_file_exists39_v0}"
if [ "$(( ! ret_file_exists39_v0__58_12 ))" != 0 ]; then
    echo "Creating the master key. Choose the master password: it is what adds new machines."
    command_35="$(age-keygen 2>/dev/null)"
    __status=$?
    if [ "${__status}" != 0 ]; then
        exit "${__status}"
    fi
    key_50="${command_35}"
    command_36="$(age-keygen -y <<<"${key_50}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        exit "${__status}"
    fi
    master_51="${command_36}"
    age --passphrase --armor -o "${master_path_25}" <<<"${key_50}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        exit "${__status}"
    fi
    initial_rules__182_v0 "${master_51}"
    ret_initial_rules182_v0__63_33="${ret_initial_rules182_v0}"
    write_rules__189_v0 "${rules_path_24}" "${ret_initial_rules182_v0__63_33}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        exit "${__status}"
    fi
    secret_files__181_v0 "${repo_23}"
    existing_172=("${ret_secret_files181_v0[@]}")
    __length_37=("${existing_172[@]}")
    if [ "$(( ${#__length_37[@]} > 0 ))" != 0 ]; then
        echo "The existing secrets are not encrypted to the new master key yet: this machine must be able to decrypt them."
        rekey_with_machine_key_47=1
    fi
fi
secret_files__181_v0 "${repo_23}"
files_173=("${ret_secret_files181_v0[@]}")
file_read__40_v0 "${rules_path_24}"
__status=$?
if [ "${__status}" != 0 ]; then
    exit "${__status}"
fi
rules_176="${ret_file_read40_v0}"
text_contains__16_v0 "${rules_176}" "${machine_45}"
ret_text_contains16_v0__73_8="${ret_text_contains16_v0}"
if [ "${ret_text_contains16_v0__73_8}" != 0 ]; then
    if [ "$(( ! rekey_with_machine_key_47 ))" != 0 ]; then
        echo "sops: this machine can already decrypt the secrets"
        exit 0
    fi
else
    __length_38=("${files_173[@]}")
    if [ "$(( $(( ${#__length_38[@]} > 0 )) && $(( ! rekey_with_machine_key_47 )) ))" != 0 ]; then
        # Before .sops.yaml changes, so a wrong password leaves nothing half
        # done. The master key only ever lives in the environment of this
        # process and the sops commands below.
        echo "Adding this machine (${host_46}) to the repo's secrets. Master password:"
        command_39="$(age --decrypt "${master_path_25}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
        code_181="${__status}"
            echo_error__138_v0 "sops-bootstrap: could not decrypt the master key (wrong password?)" 0
            exit "${code_181}"
        fi
        master_key_182="${command_39}"
        export SOPS_AGE_KEY="${master_key_182}"
        __status=$?
    fi
    add_recipient__184_v0 "${rules_176}" "${machine_45}" "${host_46}"
    rules_176="${ret_add_recipient184_v0}"
    write_rules__189_v0 "${rules_path_24}" "${rules_176}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        exit "${__status}"
    fi
fi
__length_40=("${files_173[@]}")
if [ "$(( ${#__length_40[@]} == 0 ))" != 0 ]; then
    echo "sops: added this machine to .sops.yaml; there are no secrets to re-encrypt yet"
    exit 0
fi
for file_243 in "${files_173[@]}"; do
    (cd "${repo_23}" && sops updatekeys --yes "${file_243}")
    __status=$?
    if [ "${__status}" != 0 ]; then
        exit "${__status}"
    fi
done
unset SOPS_AGE_KEY
__status=$?
echo "sops: done. Commit and push .sops.yaml and the re-encrypted secrets:"
join__7_v0 files_173[@] " "
ret_join7_v0__105_64="${ret_join7_v0}"
echo "  git -C ${repo_23} add .sops.yaml .sops-master.key.age ${ret_join7_v0__105_64}"
