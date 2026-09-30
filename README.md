# tmux-oi

One keybind that jumps to the next AI-agent session waiting for your input.

You run many Claude Code sessions across tmux panes. When one stops and needs you, it
raises a flag. Press `prefix + g` and you land on the pane that has been waiting
longest. No picker, no list. Press again for the next one.

## Install

Requires tmux 3.0 or newer (pane options). With [TPM](https://github.com/tmux-plugins/tpm), add to `~/.tmux.conf`:

```tmux
set -g @plugin 'rvonhoog/tmux-oi'
```

Then `prefix + I` to fetch it.

## Wire the hook

Claude Code fires a `Notification` hook for several events. The matcher below keeps
only the ones that mean it is waiting on you. Add this to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "permission_prompt|idle_prompt|elicitation_dialog|elicitation_url_dialog|agent_needs_input",
        "hooks": [
          {
            "type": "command",
            "command": "~/.tmux/plugins/tmux-oi/scripts/push.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

If you already have a `Notification` hook, add this as a second group next to it so
the matcher stays separate. Adjust the path if TPM cloned the plugin somewhere other
than `~/.tmux/plugins`. Claude Code picks up the change without a restart.

## Options

```tmux
set -g @oi_key 'g'   # key after prefix (default shown)
```

Set it above the `run '~/.tmux/plugins/tpm/tpm'` line, since the plugin reads it once
when tmux loads.

## How it works

- `push.sh` sets a pane option, `@oi_waiting`, to the current time on the pane Claude is
  running in. Runs from the hook. A pane already flagged keeps its original time.
- `pop.sh` lists panes carrying that option, picks the oldest, clears it, and jumps
  there with `switch-client`. Bound to the key by `oi.tmux`.
- The queue lives inside the tmux server, so it needs no file, dies with the server,
  and a closed pane can never be in it. To see it:

  ```sh
  tmux list-panes -a -f '#{@oi_waiting}' -F '#{@oi_waiting} #{pane_id} #{session_name}'
  ```
