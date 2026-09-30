#!/usr/bin/env bash
# Jump to the pane that has been waiting for input the longest and clear its flag.

# panes carrying @oi_waiting, as "<timestamp> <pane id>", oldest first
pane="$(tmux list-panes -a -f '#{@oi_waiting}' -F '#{@oi_waiting} #{pane_id}' \
    | sort -n | awk 'NR == 1 { print $2 }')"

[ -n "$pane" ] || { tmux display-message "oi: no waiting sessions"; exit 0; }

tmux set-option -pu -t "$pane" @oi_waiting \; switch-client -t "$pane"
