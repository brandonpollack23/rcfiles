_hn_cache="$HOME/.cache/hn_motd"
_hn_default_max_age=${HN_MAX_AGE:-18000} # 5 hours, overridable via env
_hn_default_count=${HN_COUNT:-30}        # top N stories to cache, overridable via env

_hn_stale() {
  local max_age=${1:-$_hn_default_max_age}
  [[ ! -f "$_hn_cache" ]] && return 0
  local age=$(($(date +%s) - $(date -r "$_hn_cache" +%s)))
  ((age > max_age))
}

_hn_fetch() {
  local count=${1:-$_hn_default_count}
  local ids id item title url text kid comment obj tmpfile
  ids=$(curl -sf https://hacker-news.firebaseio.com/v0/topstories.json) || return
  tmpfile=$(mktemp)
  echo "[]" >"$tmpfile"
  for id in $(echo "$ids" | jq ".[: ${count}][]"); do
    item=$(curl -sf "https://hacker-news.firebaseio.com/v0/item/${id}.json") || continue
    title=$(echo "$item" | jq -r '.title // empty')
    [[ -z "$title" ]] && continue
    url=$(echo "$item" | jq -r '.url // empty')
    text=$(echo "$item" | jq -r '.text // empty')
    comment=""

    if [[ -n "$url" ]]; then
      kid=$(echo "$item" | jq '.kids[0] // empty')
      if [[ -n "$kid" ]]; then
        comment=$(curl -sf "https://hacker-news.firebaseio.com/v0/item/${kid}.json" |
          jq -r '.text // empty' | sed 's/<[^>]*>//g' | tr -d '\000-\037')
        comment="${comment:0:100}"
      fi
    elif [[ -n "$text" ]]; then
      comment=$(echo "$text" | sed 's/<[^>]*>//g' | tr -d '\000-\037' | head -c 100)
      url=""
    fi

    obj=$(jq -n --arg t "$title" --arg u "$url" --arg c "$comment" \
      '{title: $t, url: $u, comment: $c}')
    jq --argjson e "$obj" '. + [$e]' "$tmpfile" >"${tmpfile}.tmp" &&
      command mv "${tmpfile}.tmp" "$tmpfile"
  done
  command mv "$tmpfile" "$_hn_cache"
}

hn() {
  local max_age=$_hn_default_max_age count=$_hn_default_count

  while [[ $# -gt 0 ]]; do
    case $1 in
    --max-age)
      max_age=$2
      shift 2
      ;;
    --count)
      count=$2
      shift 2
      ;;
    *) shift ;;
    esac
  done

  if [[ ! -f "$_hn_cache" ]] || _hn_stale "$max_age"; then
    { _hn_fetch "$count" >/dev/null 2>&1 & } 2>/dev/null
    echo "Fetching Hacker News top $count stories..."
    return
  fi

  [[ -f "$_hn_cache" ]] || return
  local entry title url comment
  entry=$(jq -c '.[]' "$_hn_cache" | shuf -n1)
  title=$(echo "$entry" | jq -r '.title')
  url=$(echo "$entry" | jq -r '.url')
  comment=$(echo "$entry" | jq -r '.comment')

  echo -e "\n🔥 \e[2mHacker News MOTD\e[22m\n"
  echo -e "📰 \e[1m${title}\e[0m"
  [[ -n "$url" ]] && echo -e "   ${url}"
  [[ -n "$comment" ]] && echo -e "   💬 \e[3m${comment}\e[23m…"
  echo
}

hn "$@"
