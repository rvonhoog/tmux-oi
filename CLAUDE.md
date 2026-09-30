# tmux-oi

A tiny tmux plugin: **one keybind that jumps to the next AI-agent session waiting for
your input.** "oi" = the noise you make to get someone's attention — which is what the
tool does on your behalf when an agent is blocked and needs you.

Status: **pop.sh, push.sh, oi.tmux and README written and tested (2026-09-30). Hook
wired in `~/.claude/settings.json` and `run-shell ~/code/tmux-oi/oi.tmux` added to the
dotfiles tmux.conf, both pointing at this checkout. Not committed yet.** This file is
the handoff so a fresh session has the full context.

## What it does (the harpoon-style, one-key-pop UX)

You run many Claude Code sessions across tmux panes. When one finishes a task and needs
input, it should get queued. Pressing the keybind (`prefix + g`) jumps you straight to
the next queued pane — **no picker, no list, no looking.** Blind pop to the next one
waiting.

This is deliberately different from the picker/dashboard tools (herdr, taimux,
grndlvl/tmux-ai-sessions, craftzdog/tmux-claude-hatch), which show a list of sessions
with status and make you choose. Those are fine; we want the zero-decision "just take me
to the next one" primitive instead.

## How it works

- **Queue = a per-pane tmux option, `@oi_waiting`, holding a unix timestamp.** No file.
  Earlier design used a queue file of pane ids; dropped on 2026-09-30 because pane ids
  are only unique per tmux *server* (a new server starts at `%0` again), so a file
  outliving the server could point at unrelated panes. Options die with the server and
  a dead pane cannot carry one, so there is no stale-entry handling at all.
- **push** — Claude Code's `Notification` hook runs `scripts/push.sh`, which sets
  `@oi_waiting` to `date +%s` on `$TMUX_PANE`. No-op outside tmux. If the pane is already
  flagged it keeps its original timestamp (its place in line).
- **pop** — `prefix + g` runs `scripts/pop.sh`: `list-panes -a -f '#{@oi_waiting}'`
  sorted by timestamp, take the oldest, unset its option, `switch-client -t <pane>`.
  Nothing flagged → `display-message "oi: no waiting sessions"`.
  - `switch-client -t %NN` alone changes session, window and pane (man page special
    case for targets containing `%`; verified live on tmux 3.7c). No select-window /
    select-pane needed.

## Intended structure (TPM plugin)

```
tmux-oi/
├── oi.tmux            # TPM entry: sourced on tmux load; reads @oi_key, sets bind-key
├── scripts/
│   ├── push.sh        # Notification hook → flag $TMUX_PANE with @oi_waiting
│   └── pop.sh         # keybind → jump to next waiting pane
└── README.md          # install + hook-wiring instructions
```

- `oi.tmux` is a shell script (that's how TPM plugins work — TPM sources any executable
  `*.tmux` in the plugin dir at startup). It reads the one user option and registers
  the bind:
  - `@oi_key` (default `g`) — the key after prefix
- Install elsewhere via TPM: `set -g @plugin 'rvonhoog/tmux-oi'` (repo not pushed yet).

## Decisions made (2026-09-24)

- Repo name `tmux-oi` (the `tmux-` prefix is the plugin convention / TPM-discoverable).
- Keybind `prefix + g` — verified free in the user's tmux config.
- Standalone project under `~/code`, NOT vendored in dotfiles. Dotfiles will just carry
  the `@plugin` line + key config once it's published.
- Build the one-key-pop version ourselves rather than adopt a picker tool.

## How to work on this (learner mode — important)

The user is a newer programmer actively learning and **wants to write the code
themselves.** Do NOT write the plugin scripts for them. Instead:
- Explain the concepts first (tmux commands, the queue logic, TPM anatomy).
- Give hints and let them draft `pop.sh` first; then review their attempt and give
  feedback.
- Point out patterns/best practices as you go; check understanding before moving on.

All three scripts are done. The user drafted the pop.sh skeleton, then asked Claude to
write the rest (2026-09-30). The file-queue version went through `/simplify`; the
altitude review surfaced the pane-id-reuse problem and the user chose the tmux-option
design over fixing the file version.

## Environment facts (from the user's setup)

- tmux config lives in the dotfiles repo at `shared/tmux/.tmux.conf` (symlinked to
  `~/.tmux.conf`). TPM is already installed and in use there.
- `~/.claude/settings.json` has two `Notification` groups: peon-ping (matcher `""`) and
  tmux-oi (matcher `permission_prompt|idle_prompt|elicitation_dialog|elicitation_url_dialog|agent_needs_input`), pointing at
  this checkout's `scripts/push.sh`. Claude Code's file watcher applies settings.json hook
  edits to running sessions; verified 2026-09-30 by seeing two panes flagged minutes after
  wiring, with no restart.
- `$TMUX_PANE` example from a live pane: `%52`.

## Related

- Spawned from beads issue **DOT-jwh** in the dotfiles repo ("tmux Claude ready-queue:
  jump to waiting sessions via keybinding"). Close/track that once tmux-oi ships.

## Next steps

1. ~~scripts, README, hook wiring, tmux.conf line~~ done.
2. Real-world test: push is verified firing (two panes flagged by real sessions). Still
   untested by a human: pressing `prefix + g` and landing on one.
3. Pre-commit workflow (`/simplify` already run on the file version; rerun on this one),
   first commit.
4. Publish to `rvonhoog/tmux-oi`; swap the tmux.conf `run-shell` line for `@plugin`;
   update the hook path in settings.json to the TPM install location.

## Follow-up ideas (user's, 2026-09-30)

- **Status-bar count**: `#(tmux list-panes -a -f '#{@oi_waiting}' | wc -l)` style
  snippet exposed as an option users can drop into `status-right`.
- **Peek/pick menu**: second key that opens `tmux display-menu` with one numbered row
  per waiting pane (session name), jumping on pick. Demoed to the user; they liked it.
  Open questions: does picking clear the flag; show session name only or also the
  pane's command.
- **Auto-clear**: if the user answers a flagged pane by hand, the flag stays and the
  next pop goes there needlessly. A `UserPromptSubmit` hook that unsets `@oi_waiting`
  would fix it.
