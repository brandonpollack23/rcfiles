#!/bin/sh
# Starts l1p0-menus, the bar's popups. It only takes its weather key and city
# from config.json, so that file is written here (and gitignored): the
# committed config.base.json, plus OWM_API_KEY from the repo's sops secrets and
# the city this IP is in. popups.py and the bar's weather button (brpol-waybard)
# read the same two from it.

DIR=$(dirname "$(readlink -f "$0")")

CITY=$(curl -fsS -m 3 https://ipinfo.io/json | jq -r '"\(.city),\(.country)"') \
	sops exec-env "$DIR/../../secrets.sops.env" \
	"jq '.[\"weather-clock\"] += {api_key: env.OWM_API_KEY, city: env.CITY}' '$DIR/config.base.json'" \
	>"$DIR/config.json" || cp "$DIR/config.base.json" "$DIR/config.json"

exec l1p0-menus --daemon
