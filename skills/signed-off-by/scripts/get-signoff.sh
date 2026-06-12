#!/usr/bin/env bash
# Extract [user] name and email from ~/.gitconfig
# Outputs: "Name <email>" on success, exits 1 on failure

set -euo pipefail

GITCONFIG="${GITCONFIG:-$HOME/.gitconfig}"

if [[ ! -f "$GITCONFIG" ]]; then
  echo "ERROR: $GITCONFIG does not exist" >&2
  exit 1
fi

name=""
email=""
in_user=false

while IFS= read -r line; do
  # Strip leading whitespace
  stripped="${line#"${line%%[![:space:]]*}"}"

  # Detect section headers
  if [[ "$stripped" == "["* ]]; then
    if [[ "$stripped" == "[user]" ]]; then
      in_user=true
    else
      in_user=false
    fi
    continue
  fi

  if $in_user; then
    key="${stripped%%=*}"
    key="${key// /}"
    val="${stripped#*=}"
    val="${val# }"  # trim leading space

    case "$key" in
      name)  name="$val" ;;
      email) email="$val" ;;
    esac
  fi
done < "$GITCONFIG"

if [[ -z "$name" ]]; then
  echo "ERROR: [user] name not found in $GITCONFIG" >&2
  exit 1
fi

if [[ -z "$email" ]]; then
  echo "ERROR: [user] email not found in $GITCONFIG" >&2
  exit 1
fi

echo "${name} <${email}>"
