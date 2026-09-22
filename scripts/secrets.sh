#!/usr/bin/env bash
#MISE description="Edit the repo's secrets (secrets.sops.env) in $EDITOR"
exec sops "$MISE_CONFIG_ROOT/secrets.sops.env"
