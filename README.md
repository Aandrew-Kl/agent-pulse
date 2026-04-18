# agent-pulse

Live terminal dashboard for long-running agent processes — Codex, Claude Opus, any subprocess. Launch an agent, and a second terminal shows what model it's using, how long it's been running, tokens consumed, log growth, and the last line it emitted. All from a shared registry on disk, so you and your orchestrator both see the same view.

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  agent-pulse  ·  17:48:21  ·  ● 2 running  ·  ○ 17 done                       ║
╚══════════════════════════════════════════════════════════════════════════════╝

▸ DataLens
────────────────────────────────────────────────────────────────────────
  ● ◎ w5_search               gpt-5.4           ⏱ 4m13s   142K tok    157KB
      search/filter endpoints                        █████████████░░░░░░░░░░░░
      └─ Added ORDER BY clause and ILIKE binding to list_bookmarks...
  ● ◎ w5_refresh              gpt-5.4           ⏱ 2m46s   — tok       5KB
      JWT expiry handling                             █░░░░░░░░░░░░░░░░░░░░░░░░
      └─ Exploring src/stores/auth-store.ts structure...
```

## Why

Running parallel agents (Codex `codex exec --full-auto`, Claude Agent SDK, shell jobs) means you cannot see what's happening unless you tail many log files at once. agent-pulse reads a tiny JSON manifest per agent and renders ONE live panel, grouped by project, showing only what's currently running. Completed agents roll into a compact counter.

## Install

```bash
git clone https://github.com/<you>/agent-pulse.git
cd agent-pulse
sudo ln -sf "$PWD/bin/agent-pulse" /usr/local/bin/agent-pulse
# or just:
export PATH="$PWD/bin:$PATH"
```

Nothing to compile. Pure bash + python3 (for JSON parsing). Works on macOS and Linux.

## Quick start

Two terminals:

```bash
# Terminal 1 — start the daemon
agent-pulse daemon &

# Terminal 2 — watch it live
agent-pulse watch
```

Third terminal whenever you want to fire off an agent:

```bash
agent-pulse dispatch \
  --id demo \
  --label "sample codex run" \
  --project my-project \
  --model gpt-5.4 \
  --worktree /tmp/my-worktree \
  --brief /tmp/my-brief.md
```

Switch back to Terminal 2 — the agent appears immediately, log size bar grows, elapsed time ticks. When it exits, it drops out of the running list and the `done` counter ticks up.

## What it tracks per agent

| field | source |
|---|---|
| `id` | you (manifest key) |
| `label` | you (human-readable sub-title) |
| `project` | you (grouping key in the panel) |
| `model` | you (display color: Opus=purple, GPT-5=blue, Sonnet=cyan, other=yellow) |
| `kind` | you (codex/opus/shell/…) — controls the icon (◎ codex, ★ opus, ◇ other) |
| `started_at` | set by `dispatch` → renders elapsed |
| `pid` | set by `dispatch` → used to detect alive/done |
| `log_file` | set by `dispatch` → size bar + `grep` for tokens + last line |

Token extraction regex today: `tokens used N` and `tokens_used: N`. If your agent emits a different format, extend `render()` in `bin/agent-pulse`.

## Registry layout

Default location: `$HOME/.agent-pulse/`

```
$HOME/.agent-pulse/
├── registry/
│   ├── w5_search.json
│   ├── w5_refresh.json
│   └── ...
├── <id>.log        # written by the agent subprocess
├── <id>.pid        # written by dispatch
├── live.txt        # rendered panel (daemon writes, watch reads)
└── daemon.pid
```

Override via `export AGENT_PULSE_HOME=/path/to/whatever` — useful if you're running agents as multiple users or want per-project registries.

## Subcommands

| subcommand | effect |
|---|---|
| `agent-pulse daemon` | loop-render the panel into `live.txt` every 2s (backgrounded with `&`) |
| `agent-pulse watch` | clear+cat loop against `live.txt` — what the user stares at |
| `agent-pulse list` | one-shot render to stdout (for pipes / scripts) |
| `agent-pulse stop` | stop the daemon |
| `agent-pulse dispatch --id --label --project [--model --kind --worktree --brief \| --cmd]` | launch + register |

## Dispatch modes

### Codex (default)

```bash
agent-pulse dispatch \
  --id w5_search \
  --label "search endpoints" \
  --project DataLens \
  --model gpt-5.4 \
  --worktree /tmp/worktree \
  --brief /tmp/brief.md
```

Runs `codex exec --full-auto -m <model> -C <worktree> "$(cat <brief>)"`.

### Any shell command

```bash
agent-pulse dispatch \
  --id build --label "full rebuild" \
  --project my-app --kind shell --model none \
  --cmd "cd /path/to/app && npm run build"
```

The daemon still tracks elapsed time + log growth + last line.

## Why a shared file (and not a TUI)

Because two viewers — you and me (the orchestrator) — need to see the exact same state without fighting over a terminal. One daemon writes, many readers watch. If you prefer a fullscreen TUI locally, wrap `list` in your own renderer.

## Roadmap

- Long-lived agent groups (blocks of siblings that should render as one row)
- Terminal-agnostic web viewer (same live.txt rendered over HTTP)
- History view of completed runs
- Per-project registry via `--home` flag instead of env var

## License

MIT.
