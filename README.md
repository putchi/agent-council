# Agent Council

Agent Council runs a question through four expert AI roles, then asks a Chairman to synthesize the result into a direct decision. It supports four council domains: tech, career, business, and personal.

This repository packages Agent Council for both Claude Code and Codex.

## Install

Install directly from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/putchi/agent-council/main/install.sh | bash
```

You can also skip the platform prompt:

```bash
curl -fsSL https://raw.githubusercontent.com/putchi/agent-council/main/install.sh | bash -s -- --platform claude
curl -fsSL https://raw.githubusercontent.com/putchi/agent-council/main/install.sh | bash -s -- --platform codex
curl -fsSL https://raw.githubusercontent.com/putchi/agent-council/main/install.sh | bash -s -- --platform both
```

Or, register the marketplace in Claude Code and install from there:

```text
/plugin marketplace add putchi/agent-council
/plugin install agent-council@agent-council
```

Clone the repo:

```bash
git clone git@github.com-secondary:putchi/agent-council.git
cd agent-council
```

Run the installer and choose a platform:

```bash
./install.sh
```

You can also skip the prompt:

```bash
./install.sh --platform claude
./install.sh --platform codex
./install.sh --platform both
```

Install targets:

| Platform | Install path |
|---|---|
| Claude Code | `~/.claude/plugins/cache/agent-council/agent-council/<version>` |
| Codex | `~/.codex/skills/agent-council` |

For active Claude Code sessions, run `/reload-plugins` after installing or updating.

## Usage

Claude Code and Codex can load the installed skill by name:

```text
Use agent-council for this decision: should we migrate this service to microservices?
```

You can also run the scripts directly from the installed skill:

```bash
bash ~/.codex/skills/agent-council/scripts/run-council.sh --council career "How should I answer why I am leaving my current job?"
```

Available councils:

| Council | Use for |
|---|---|
| `tech` | Architecture, engineering tradeoffs, implementation decisions |
| `career` | Interviews, negotiation, career positioning |
| `business` | Strategy, market, financial and execution decisions |
| `personal` | Personal tradeoffs, life decisions, practical consequences |

If you omit `--council`, the skill classifies the question automatically.

## Platform Notes

The Claude Code install is a plugin install. It enables `agent-council@agent-council` in `~/.claude/settings.json`, adds the marketplace under `~/.claude/plugins/marketplaces/agent-council`, and installs the versioned plugin cache under `~/.claude/plugins/cache/agent-council/agent-council/<version>`.

The Codex skill uses the `codex` CLI and installs to `~/.codex/skills/agent-council`.

Both variants keep the same council structure and output format, but their runtime scripts call the platform-native CLI.

## Updates

For Claude Code plugin installs, this repo includes a `UserPromptSubmit` hook that checks once per session whether a newer version is available at:

```text
https://raw.githubusercontent.com/putchi/agent-council/main/.claude-plugin/marketplace.json
```

When a newer version is published, Claude Code will show an update prompt. Installs can be updated with:

```bash
curl -fsSL https://raw.githubusercontent.com/putchi/agent-council/main/install.sh | bash -s -- --platform both
```

## Repository Layout

```text
.
├── .claude-plugin/          # Claude Code plugin and marketplace metadata
├── hooks/                   # Claude Code update hook
├── skills/
│   ├── agent-council        # Claude plugin skill source
│   └── codex/agent-council  # Codex installer source
├── install.sh               # Interactive installer
└── README.md
```

## Requirements

- Bash
- `codex` CLI authenticated for Codex installs
- `python3` for Claude plugin metadata installation
- `curl` for remote installation and the Claude Code update hook

## License

MIT
