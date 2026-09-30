#!/usr/bin/env bash
# Mark the current tmux pane as waiting for input.
# Meant to run from Claude Code's Notification hook. Does nothing outside tmux.

[ -n "$TMUX_PANE" ] || exit 0

# already flagged: keep the original timestamp so the pane keeps its place in line
[ -n "$(tmux show-option -pqv -t "$TMUX_PANE" @oi_waiting)" ] && exit 0

tmux set-option -p -t "$TMUX_PANE" @oi_waiting "$(date +%s)"
