#!/usr/bin/env bash
# GENERATED from scripts/hacker-news/main.ab by scripts/build.ab. Edit the .ab sources, then run: mise run build
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
    local text_208="${1}"
    local delimiter_209="${2}"
    local result_210=()
    # zsh uses -A for array, bash uses -a, ksh is VERY bad at splitting anything
    if [ "$([ "_${EXEC_SHELL}" != "_zsh" ]; echo $?)" != 0 ]; then
        IFS="${delimiter_209}" read -rd '' -A result_210 < <(printf %s "$text_208")
        __status=$?
    elif [ "$([ "_${EXEC_SHELL}" != "_ksh" ]; echo $?)" != 0 ]; then
        if [ "$([ "_${delimiter_209}" != "_
" ]; echo $?)" != 0 ]; then
            while read -r -d $'\n'; do result_210+=("$REPLY"); done < <(echo "$text_208")
            __status=$?
        else
            IFS="${delimiter_209}" read -rd '' -a result_210 < <(printf %s "$text_208")
            __status=$?
        fi
    elif [ "$([ "_${EXEC_SHELL}" != "_bash" ]; echo $?)" != 0 ]; then
        IFS="${delimiter_209}" read -rd '' -a result_210 < <(printf %s "$text_208")
        __status=$?
    fi
    ret_split4_v0=("${result_210[@]}")
    return 0
}

# split_lines(text: Text)
split_lines__5_v0() {
    local text_207="${1}"
    split__4_v0 "${text_207}" "
"
    ret_split_lines5_v0=("${ret_split4_v0[@]}")
    return 0
}

# trim(text: Text)
trim__10_v0() {
    local text_226="${1}"
    local result_227=""
    result_227="${text_226#${text_226%%[![:space:]]*}}"
    __status=$?
    result_227="${result_227%${result_227##*[![:space:]]}}"
    __status=$?
    ret_trim10_v0="${result_227}"
    return 0
}

# parse_int(text: Text)
parse_int__13_v0() {
    local text_40="${1}"
    [ -n "${text_40}" ] && [ "${text_40}" -eq "${text_40}" ] 2>/dev/null
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_parse_int13_v0=''
        return "${__status}"
    fi
    ret_parse_int13_v0="${text_40}"
    return 0
}

# starts_with(text: Text, prefix: Text)
starts_with__22_v0() {
    local text_277="${1}"
    local prefix_278="${2}"
    [[ "${text_277}" == "${prefix_278}"* ]]
    __status=$?
    ret_starts_with22_v0="$(( __status == 0 ))"
    return 0
}

# slice(text: Text, index: Int, length: Int)
slice__24_v0() {
    local text_228="${1}"
    local index_229="${2}"
    local length_230="${3}"
    local result_231=""
    if [ "$(( length_230 == 0 ))" != 0 ]; then
        local __length_1="${text_228}"
        length_230="$(( ${#__length_1} - index_229 ))"
    fi
    if [ "$(( length_230 <= 0 ))" != 0 ]; then
        ret_slice24_v0="${result_231}"
        return 0
    fi
    result_231="${text_228: ${index_229}: ${length_230}}"
    __status=$?
    ret_slice24_v0="${result_231}"
    return 0
}

# file_exists(path: Text)
file_exists__39_v0() {
    local path_235="${1}"
    [ -f "${path_235}" ]
    __status=$?
    ret_file_exists39_v0="$(( __status == 0 ))"
    return 0
}

# env_var_get(name: Text)
env_var_get__120_v0() {
    local name_42="${1}"
    if [ "$([ "_${EXEC_SHELL}" != "_bash" ]; echo $?)" != 0 ]; then
        local command_2
        command_2="$(printf "%s
" "${!name_42}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_env_var_get120_v0=''
            return "${__status}"
        fi
        ret_env_var_get120_v0="${command_2}"
        return 0
    elif [ "$([ "_${EXEC_SHELL}" != "_zsh" ]; echo $?)" != 0 ]; then
        local command_3
        command_3="$(printf "%s
" "${(P)name_42}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_env_var_get120_v0=''
            return "${__status}"
        fi
        ret_env_var_get120_v0="${command_3}"
        return 0
    elif [ "$([ "_${EXEC_SHELL}" != "_ksh" ]; echo $?)" != 0 ]; then
        local command_4
        command_4="$(eval "echo \${$name_42}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_env_var_get120_v0=''
            return "${__status}"
        fi
        ret_env_var_get120_v0="${command_4}"
        return 0
    fi
}

# Command-line and environment settings.
__DEFAULT_MAX_AGE_3=18000
# 5 hours
__DEFAULT_COUNT_4=30
# The value after `flag` in args, or "" when the flag is absent or last.
# flag_value(args: [Text], flag: Text)
flag_value__159_v0() {
    local args_35=("${!1}")
    local flag_36="${2}"
    i_38=0;
    for arg_37 in "${args_35[@]}"; do
        local __length_7=("${args_35[@]}")
        if [ "$(( $([ "_${arg_37}" != "_${flag_36}" ]; echo $?) && $(( $(( i_38 + 1 )) < ${#__length_7[@]} )) ))" != 0 ]; then
            ret_flag_value159_v0="${args_35[$(( i_38 + 1 ))]?"Index out of bounds (at scripts/hacker-news/./src/args.ab:13:25)"}"
            return 0
        fi
        (( i_38++ )) || true
    done
    ret_flag_value159_v0=""
    return 0
}

# has_flag(args: [Text], flag: Text)
has_flag__160_v0() {
    local args_53=("${!1}")
    local flag_54="${2}"
    for arg_55 in "${args_53[@]}"; do
        if [ "$([ "_${arg_55}" != "_${flag_54}" ]; echo $?)" != 0 ]; then
            ret_has_flag160_v0=1
            return 0
        fi
    done
    ret_has_flag160_v0=0
    return 0
}

# The first non-empty of the flag value, the environment variable, and the
# default. A value that is not a whole number falls through to the next one.
# int_setting(args: [Text], flag: Text, env: Text, default: Int)
int_setting__161_v0() {
    local args_31=("${!1}")
    local flag_32="${2}"
    local env_33="${3}"
    local default_34="${4}"
    flag_value__159_v0 args_31[@] "${flag_32}"
    local from_flag_39="${ret_flag_value159_v0}"
    if [ "$([ "_${from_flag_39}" == "_" ]; echo $?)" != 0 ]; then
        parse_int__13_v0 "${from_flag_39}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_int_setting161_v0="${default_34}"
            return 0
        fi
        local n_41="${ret_parse_int13_v0}"
        ret_int_setting161_v0="${n_41}"
        return 0
    fi
    env_var_get__120_v0 "${env_33}"
    __status=$?
    local from_env_43="${ret_env_var_get120_v0}"
    if [ "$([ "_${from_env_43}" == "_" ]; echo $?)" != 0 ]; then
        parse_int__13_v0 "${from_env_43}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_int_setting161_v0="${default_34}"
            return 0
        fi
        local n_44="${ret_parse_int13_v0}"
        ret_int_setting161_v0="${n_44}"
        return 0
    fi
    ret_int_setting161_v0="${default_34}"
    return 0
}

# The story cache: a JSON array of {title, url, comment} objects.
# cache_path()
cache_path__167_v0() {
    env_var_get__120_v0 "HOME"
    __status=$?
    local home_48="${ret_env_var_get120_v0}"
    ret_cache_path167_v0="${home_48}/.cache/hn_motd"
    return 0
}

# Seconds since the file was last written. GNU stat first, then BSD/macOS.
# A file that cannot be read counts as brand new.
# file_age(path: Text)
file_age__168_v0() {
    local path_298="${1}"
    local command_10
    command_10="$(date +%s)"
    __status=$?
    parse_int__13_v0 "${command_10}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_file_age168_v0=0
        return 0
    fi
    local now_299="${ret_parse_int13_v0}"
    local command_11
    command_11="$(stat -c %Y "${path_298}" 2>/dev/null || stat -f %m "${path_298}" 2>/dev/null)"
    __status=$?
    parse_int__13_v0 "${command_11}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_file_age168_v0=0
        return 0
    fi
    local mtime_300="${ret_parse_int13_v0}"
    ret_file_age168_v0="$(( now_299 - mtime_300 ))"
    return 0
}

# is_stale(age: Int, max_age: Int)
is_stale__169_v0() {
    local age_301="${1}"
    local max_age_302="${2}"
    ret_is_stale169_v0="$(( age_301 > max_age_302 ))"
    return 0
}

# cache_is_stale(path: Text, max_age: Int)
cache_is_stale__170_v0() {
    local path_296="${1}"
    local max_age_297="${2}"
    file_exists__39_v0 "${path_296}"
    local ret_file_exists39_v0__29_12="${ret_file_exists39_v0}"
    if [ "$(( ! ret_file_exists39_v0__29_12 ))" != 0 ]; then
        ret_cache_is_stale170_v0=1
        return 0
    fi
    file_age__168_v0 "${path_296}"
    local ret_file_age168_v0__32_21="${ret_file_age168_v0}"
    is_stale__169_v0 "${ret_file_age168_v0__32_21}" "${max_age_297}"
    ret_cache_is_stale170_v0="${ret_is_stale169_v0}"
    return 0
}

# A refresh holds this directory so several shells opening at once start one
# fetch between them. A lock older than 10 minutes is left from a killed run.
# The story cache: a JSON array of {title, url, comment} objects.
# Seconds since the file was last written. GNU stat first, then BSD/macOS.
# A file that cannot be read counts as brand new.
# file_age(path: Text)
file_age__183_v0() {
    local path_200="${1}"
    local command_12
    command_12="$(date +%s)"
    __status=$?
    parse_int__13_v0 "${command_12}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_file_age183_v0=0
        return 0
    fi
    local now_201="${ret_parse_int13_v0}"
    local command_13
    command_13="$(stat -c %Y "${path_200}" 2>/dev/null || stat -f %m "${path_200}" 2>/dev/null)"
    __status=$?
    parse_int__13_v0 "${command_13}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_file_age183_v0=0
        return 0
    fi
    local mtime_202="${ret_parse_int13_v0}"
    ret_file_age183_v0="$(( now_201 - mtime_202 ))"
    return 0
}

# A refresh holds this directory so several shells opening at once start one
# fetch between them. A lock older than 10 minutes is left from a killed run.
# lock_path(path: Text)
lock_path__186_v0() {
    local path_198="${1}"
    ret_lock_path186_v0="${path_198}.lock"
    return 0
}

# take_lock(path: Text)
take_lock__187_v0() {
    local path_197="${1}"
    lock_path__186_v0 "${path_197}"
    local dir_199="${ret_lock_path186_v0}"
    mkdir "${dir_199}" 2>/dev/null
    __status=$?
    if [ "${__status}" != 0 ]; then
        file_age__183_v0 "${dir_199}"
        local ret_file_age183_v0__44_12="${ret_file_age183_v0}"
        if [ "$(( ret_file_age183_v0__44_12 < 600 ))" != 0 ]; then
            ret_take_lock187_v0=0
            return 0
        fi
        rmdir "${dir_199}"
        __status=$?
        mkdir "${dir_199}" 2>/dev/null
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_take_lock187_v0=0
            return 0
        fi
    fi
    ret_take_lock187_v0=1
    return 0
}

# release_lock(path: Text)
release_lock__188_v0() {
    local path_204="${1}"
    lock_path__186_v0 "${path_204}"
    local ret_lock_path186_v0__56_21="${ret_lock_path186_v0}"
    rmdir "${ret_lock_path186_v0__56_21}" 2>/dev/null
    __status=$?
}

# Downloads the top stories into the cache.
__API_7="https://hacker-news.firebaseio.com/v0"
__SNIPPET_LENGTH_8=100
# Plain text from an HN comment or post body: tags dropped, the common
# entities decoded, control characters removed.
# strip_html(html: Text)
strip_html__191_v0() {
    local html_225="${1}"
    local command_14
    command_14="$(printf '%s' "${html_225}"         | sed -e 's/<[^>]*>/ /g' -e 's/&#x27;/'"'"'/g' -e 's/&#x2F;/\//g'               -e 's/&quot;/"/g' -e 's/&gt;/>/g' -e 's/&lt;/</g' -e 's/&amp;/\&/g'         | tr -d '\000-\037' | tr -s ' ')"
    __status=$?
    ret_strip_html191_v0="${command_14}"
    return 0
}

# snippet(html: Text)
snippet__192_v0() {
    local html_224="${1}"
    strip_html__191_v0 "${html_224}"
    local ret_strip_html191_v0__19_23="${ret_strip_html191_v0}"
    trim__10_v0 "${ret_strip_html191_v0__19_23}"
    local ret_trim10_v0__19_18="${ret_trim10_v0}"
    slice__24_v0 "${ret_trim10_v0__19_18}" 0 "${__SNIPPET_LENGTH_8}"
    ret_snippet192_v0="${ret_slice24_v0}"
    return 0
}

# A field of a JSON document, or "" when it is missing or null.
# json_field(json: Text, field: Text)
json_field__193_v0() {
    local json_214="${1}"
    local field_215="${2}"
    local command_15
    command_15="$(printf '%s' "${json_214}" | jq -r ".${field_215} // empty")"
    __status=$?
    ret_json_field193_v0="${command_15}"
    return 0
}

# get_json(path: Text)
get_json__194_v0() {
    local path_203="${1}"
    local command_16
    command_16="$(curl -sf --max-time 10 "${__API_7}/${path_203}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_get_json194_v0=''
        return "${__status}"
    fi
    ret_get_json194_v0="${command_16}"
    return 0
}

# One cache entry for a story, or "" when the story has no title. Link posts
# get their top comment, text posts their own body.
# story_entry(item: Text)
story_entry__195_v0() {
    local item_213="${1}"
    json_field__193_v0 "${item_213}" "title"
    local title_216="${ret_json_field193_v0}"
    if [ "$([ "_${title_216}" != "_" ]; echo $?)" != 0 ]; then
        ret_story_entry195_v0=""
        return 0
    fi
    json_field__193_v0 "${item_213}" "url"
    local url_217="${ret_json_field193_v0}"
    local comment_218=""
    if [ "$([ "_${url_217}" == "_" ]; echo $?)" != 0 ]; then
        local command_17
        command_17="$(printf '%s' "${item_213}" | jq -r '.kids[0] // empty')"
        __status=$?
        local kid_219="${command_17}"
        if [ "$([ "_${kid_219}" == "_" ]; echo $?)" != 0 ]; then
            get_json__194_v0 "item/${kid_219}.json"
            __status=$?
            if [ "${__status}" != 0 ]; then
                entry_json__196_v0 "${title_216}" "${url_217}" ""
                ret_story_entry195_v0="${ret_entry_json196_v0}"
                return 0
            fi
            local reply_223="${ret_get_json194_v0}"
            json_field__193_v0 "${reply_223}" "text"
            local ret_json_field193_v0__46_31="${ret_json_field193_v0}"
            snippet__192_v0 "${ret_json_field193_v0__46_31}"
            comment_218="${ret_snippet192_v0}"
        fi
    else
        json_field__193_v0 "${item_213}" "text"
        local ret_json_field193_v0__49_27="${ret_json_field193_v0}"
        snippet__192_v0 "${ret_json_field193_v0__49_27}"
        comment_218="${ret_snippet192_v0}"
    fi
    entry_json__196_v0 "${title_216}" "${url_217}" "${comment_218}"
    ret_story_entry195_v0="${ret_entry_json196_v0}"
    return 0
}

# entry_json(title: Text, url: Text, comment: Text)
entry_json__196_v0() {
    local title_220="${1}"
    local url_221="${2}"
    local comment_222="${3}"
    local command_18
    command_18="$(jq -cn --arg t "${title_220}" --arg u "${url_221}" --arg c "${comment_222}"         '{title: $t, url: $u, comment: $c}')"
    __status=$?
    ret_entry_json196_v0="${command_18}"
    return 0
}

# Writes the top `count` stories to `dest` atomically. Returns quietly when
# another refresh holds the lock or the network is down.
# refresh(count: Int, dest: Text)
refresh__197_v0() {
    local count_195="${1}"
    local dest_196="${2}"
    take_lock__187_v0 "${dest_196}"
    local ret_take_lock187_v0__62_12="${ret_take_lock187_v0}"
    if [ "$(( ! ret_take_lock187_v0__62_12 ))" != 0 ]; then
        ret_refresh197_v0=''
        return 0
    fi
    get_json__194_v0 "topstories.json"
    __status=$?
    if [ "${__status}" != 0 ]; then
        release_lock__188_v0 "${dest_196}"
        ret_refresh197_v0=''
        return 1
    fi
    local ids_205="${ret_get_json194_v0}"
    local entries_206="${dest_196}.entries"
    mkdir -p "$(dirname "${dest_196}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_refresh197_v0=''
        return "${__status}"
    fi
    : >"${entries_206}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_refresh197_v0=''
        return "${__status}"
    fi
    local command_21
    command_21="$(printf '%s' "${ids_205}" | jq -r '.[:'"${count_195}"'][]')"
    __status=$?
    split_lines__5_v0 "${command_21}"
    local ret_split_lines5_v0__72_15=("${ret_split_lines5_v0[@]}")
    for id_211 in "${ret_split_lines5_v0__72_15[@]}"; do
        get_json__194_v0 "item/${id_211}.json"
        __status=$?
        if [ "${__status}" != 0 ]; then
            continue
        fi
        local item_212="${ret_get_json194_v0}"
        story_entry__195_v0 "${item_212}"
        local entry_232="${ret_story_entry195_v0}"
        if [ "$([ "_${entry_232}" == "_" ]; echo $?)" != 0 ]; then
            printf '%s
' "${entry_232}" >>"${entries_206}"
            __status=$?
            if [ "${__status}" != 0 ]; then
                ret_refresh197_v0=''
                return "${__status}"
            fi
        fi
    done
    jq -s '.' "${entries_206}" >"${dest_196}.tmp" && mv -f "${dest_196}.tmp" "${dest_196}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        rm -f "${entries_206}" "${dest_196}.tmp"
        __status=$?
        release_lock__188_v0 "${dest_196}"
        ret_refresh197_v0=''
        return 1
    fi
    rm -f "${entries_206}"
    __status=$?
    release_lock__188_v0 "${dest_196}"
}

# Prints one random story from the cache.
# Title, URL and comment of a random cached story, one per line and prefixed
# with T, U and C so an empty field still has a line. One jq process: this runs
# on every new shell. "" when the cache is empty or unreadable.
# random_story(path: Text)
random_story__202_v0() {
    local path_272="${1}"
    local command_22
    command_22="$(jq -r --argjson r "$RANDOM"         '.[$r % length] | "T" + .title, "U" + (.url // ""), "C" + (.comment // "")'         "${path_272}" 2>/dev/null)"
    __status=$?
    ret_random_story202_v0="${command_22}"
    return 0
}

# The field with the given prefix letter from random_story's output.
# story_field(story: Text, prefix: Text)
story_field__203_v0() {
    local story_274="${1}"
    local prefix_275="${2}"
    split_lines__5_v0 "${story_274}"
    local ret_split_lines5_v0__16_17=("${ret_split_lines5_v0[@]}")
    for line_276 in "${ret_split_lines5_v0__16_17[@]}"; do
        starts_with__22_v0 "${line_276}" "${prefix_275}"
        local ret_starts_with22_v0__17_12="${ret_starts_with22_v0}"
        if [ "${ret_starts_with22_v0__17_12}" != 0 ]; then
            slice__24_v0 "${line_276}" 1 0
            ret_story_field203_v0="${ret_slice24_v0}"
            return 0
        fi
    done
    ret_story_field203_v0=""
    return 0
}

# The MOTD block for one story, with terminal styling.
# motd(title: Text, url: Text, comment: Text)
motd__204_v0() {
    local title_280="${1}"
    local url_281="${2}"
    local comment_282="${3}"
    local command_25
    command_25="$(printf '
🔥 \033[2mHacker News MOTD\033[22m

📰 \033[1m%s\033[0m' "${title_280}")"
    __status=$?
    local out_283="${command_25}"
    if [ "$([ "_${url_281}" == "_" ]; echo $?)" != 0 ]; then
        out_283+="
   ${url_281}"
    fi
    if [ "$([ "_${comment_282}" == "_" ]; echo $?)" != 0 ]; then
        local command_26
        command_26="$(printf '
   💬 \033[3m%s\033[23m…' "${comment_282}")"
        __status=$?
        out_283+="${command_26}"
    fi
    ret_motd204_v0="${out_283}""
"
    return 0
}

# print_story(path: Text)
print_story__205_v0() {
    local path_271="${1}"
    random_story__202_v0 "${path_271}"
    local story_273="${ret_random_story202_v0}"
    story_field__203_v0 "${story_273}" "T"
    local title_279="${ret_story_field203_v0}"
    if [ "$([ "_${title_279}" != "_" ]; echo $?)" != 0 ]; then
        ret_print_story205_v0=0
        return 0
    fi
    story_field__203_v0 "${story_273}" "U"
    local ret_story_field203_v0__42_22="${ret_story_field203_v0}"
    story_field__203_v0 "${story_273}" "C"
    local ret_story_field203_v0__42_47="${ret_story_field203_v0}"
    motd__204_v0 "${title_279}" "${ret_story_field203_v0__42_22}" "${ret_story_field203_v0__42_47}"
    local ret_motd204_v0__42_10="${ret_motd204_v0}"
    printf '%s\n' "${ret_motd204_v0__42_10}"
    ret_print_story205_v0=1
    return 0
}

# Hacker News MOTD: prints a random top story from a local cache, refreshing
# the cache in the background once it is older than --max-age seconds.
# 
# hacker-news.sh [--max-age SECONDS] [--count N]
# hacker-news.sh --refresh [--count N]     fetch now, in the foreground
# 
# Defaults come from HN_MAX_AGE (5 hours) and HN_COUNT (30). The cache is
# ~/.cache/hn_motd. .zshrc runs this on every new shell, so it never waits on
# the network: a refresh runs detached and the next shell shows its result.
typeset -r args_9=("$0" "$@")
int_setting__161_v0 args_9[@] "--count" "HN_COUNT" "${__DEFAULT_COUNT_4}"
count_45="${ret_int_setting161_v0}"
int_setting__161_v0 args_9[@] "--max-age" "HN_MAX_AGE" "${__DEFAULT_MAX_AGE_3}"
max_age_46="${ret_int_setting161_v0}"
cache_path__167_v0 
cache_49="${ret_cache_path167_v0}"
has_flag__160_v0 args_9[@] "--refresh"
ret_has_flag160_v0__22_8="${ret_has_flag160_v0}"
if [ "${ret_has_flag160_v0__22_8}" != 0 ]; then
    refresh__197_v0 "${count_45}" "${cache_49}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        exit "${__status}"
    fi
    exit 0
fi
shown_233=0
file_exists__39_v0 "${cache_49}"
ret_file_exists39_v0__28_8="${ret_file_exists39_v0}"
if [ "${ret_file_exists39_v0__28_8}" != 0 ]; then
    print_story__205_v0 "${cache_49}"
    shown_233="${ret_print_story205_v0}"
fi
cache_is_stale__170_v0 "${cache_49}" "${max_age_46}"
ret_cache_is_stale170_v0__31_8="${ret_cache_is_stale170_v0}"
if [ "${ret_cache_is_stale170_v0__31_8}" != 0 ]; then
    # args[0] is this script; it refreshes itself detached from the shell.
    nohup "${args_9[0]?"Index out of bounds (at scripts/hacker-news/main.ab:33:30)"}" --refresh --count ${count_45} >/dev/null 2>&1 &
    __status=$?
    if [ "$(( ! shown_233 ))" != 0 ]; then
        echo "⏳ Fetching the top ${count_45} Hacker News stories in the background..."
    fi
fi
