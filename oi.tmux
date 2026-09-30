#!/usr/bin/env bash
# TPM entry point: sourced when tmux starts. Reads the key option and binds it.
#   set -g @oi_key 'g'   # key after prefix (default g)

plugin_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
key="$(tmux show-option -gqv @oi_key)"

tmux bind-key "${key:-g}" run-shell "'$plugin_dir/scripts/pop.sh'"
