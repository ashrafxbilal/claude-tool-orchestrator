# Claude Tool Orchestrator

Claude Tool Orchestrator is a small Claude Code setup that keeps expensive reasoning on Sonnet or Opus while routing tool-heavy work through Haiku subagents.

The pattern is:

1. The top-level Claude Code session runs a reasoning-only `orchestrator` agent.
2. That top-level agent only has the `Task` tool.
3. Tool-heavy work is delegated to custom agents configured with `model: haiku`.

This is useful when your Claude Code setup has many MCP tools, custom agents, Slack/GitHub/Kubernetes/database helpers, or large repository workflows. The top-level model still plans and synthesizes, but the repeated file, shell, MCP, and integration calls are handled by cheaper Haiku workers.

## Repository

```text
https://github.com/ashrafxbilal/claude-tool-orchestrator
```

## What Gets Installed

The installer adds:

- `~/.claude/agents/orchestrator.md`
  - A top-level reasoning agent with `tools: Task` and `model: sonnet`.
- `~/.local/bin/claude-tool-orchestrator`
  - A launcher for strict orchestrator mode.
By default, the installer also scans existing custom agents under `~/.claude/agents` and changes:

```yaml
model: inherit
```

to:

```yaml
model: haiku
```

Every changed file is backed up first with a timestamp suffix.

## Prerequisites

- Claude Code installed and available as `claude` on your `PATH`.
- A shell environment that can run Bash scripts.
- Custom agents stored in `~/.claude/agents` if you want the installer to convert existing agents to Haiku workers.

## Quick Start

```bash
git clone https://github.com/ashrafxbilal/claude-tool-orchestrator.git
cd claude-tool-orchestrator
./install.sh
```

Start strict orchestration mode:

```bash
claude-tool-orchestrator
```

Use Opus for top-level reasoning:

```bash
CLAUDE_ORCHESTRATOR_MODEL=opus claude-tool-orchestrator
```

## Install Without Updating Existing Agents

If you only want the orchestrator agent and launcher, and do not want the installer to edit existing custom agents:

```bash
SKIP_AGENT_MODEL_UPDATE=1 ./install.sh
```

You can then manually choose which agents should run on Haiku.

## Manual Agent Configuration

For tool-heavy agents, use:

```yaml
---
name: github-cli
description: GitHub operations worker.
tools: Read, Grep, Glob, Bash, Task
model: haiku
permissionMode: default
---
```

Good Haiku-worker candidates:

- GitHub or `gh` CLI agents
- Slack agents
- Kubernetes or deployment agents
- Database/query agents
- Log search agents
- Drive/document search agents
- Test execution agents
- File-search or codebase exploration agents

Agents that may still deserve Sonnet or Opus:

- Architecture agents
- Deep code review agents
- Product/design reasoning agents
- Agents expected to make broad judgment calls without tight instructions

The pattern is flexible. You can keep any agent on Sonnet or Opus by setting its frontmatter explicitly:

```yaml
model: sonnet
```

or:

```yaml
model: opus
```

## How It Works

The launcher runs Claude Code like this:

```bash
claude --agent orchestrator --model sonnet --tools Task
```

The top-level session can reason, plan, and summarize, but it cannot directly call tools like `Read`, `Bash`, Slack, GitHub, Kubernetes, database, or MCP tools. Any tool work must be delegated with `Task`.

When a delegated custom agent has:

```yaml
model: haiku
```

that worker decides and performs the tool-heavy steps using Haiku.

## What This Optimizes

This pattern can reduce usage of higher-end models for workflows that involve many repeated tool calls, such as:

- Reading many files
- Searching large repositories
- Running commands and tests
- Checking CI or PR state
- Querying Slack or GitHub
- Inspecting Kubernetes resources
- Looking up logs or metrics
- Gathering context from internal systems

The higher-end model is reserved for:

- Understanding the user's actual goal
- Planning the sequence of work
- Deciding which subagents should handle each slice
- Combining worker results
- Making final tradeoffs and recommendations

## Example Workflow

User asks:

```text
Investigate why this PR is failing CI and suggest a fix.
```

The Sonnet orchestrator should delegate:

```text
Task(github-cli): Check the PR CI failures and summarize the failing jobs.
Task(swe-engineer): Inspect the failing test area and identify likely causes.
```

The Haiku workers gather facts and return summaries. The Sonnet orchestrator then decides the next step and writes the final answer.

## File Layout

```text
.
├── README.md
├── claude-tool-orchestrator
├── install.sh
└── orchestrator.md
```

## Rollback

The installer creates timestamped backups before overwriting files.

Examples:

```text
~/.claude/agents/orchestrator.md.bak-20260511-001122
~/.claude/agents/github-cli.md.bak-20260511-001122
~/.local/bin/claude-tool-orchestrator.bak-20260511-001122
```

To roll back an agent manually:

```bash
cp ~/.claude/agents/github-cli.md.bak-YYYYMMDD-HHMMSS ~/.claude/agents/github-cli.md
```

## Uninstall

Remove the installed launcher files:

```bash
rm -f ~/.local/bin/claude-tool-orchestrator
```

Remove the orchestrator agent:

```bash
rm -f ~/.claude/agents/orchestrator.md
```

Then restore any agent backups if you want to undo `model: haiku` changes.

## Caveats

- Claude Code does not currently expose a separate "tool-call model" setting for a single session.
- Tool execution itself is not performed by a model. The model decides which tool to call and with what arguments.
- The top-level Sonnet or Opus session still makes the `Task` delegation call.
- This pattern works by forcing the top-level session to delegate and by configuring delegated agents to use Haiku.
- If you start normal `claude`, the top-level model can still use whatever tools are available in that normal session.

Use `claude-tool-orchestrator` when you want strict separation.

## Troubleshooting

Check that Claude Code can see the orchestrator agent:

```bash
ls ~/.claude/agents/orchestrator.md
```

Check that the launcher is executable:

```bash
ls -l ~/.local/bin/claude-tool-orchestrator
```

Check which custom agents still inherit the top-level model:

```bash
rg '^model: inherit$' ~/.claude/agents
```

Check which custom agents run on Haiku:

```bash
rg '^model: haiku$' ~/.claude/agents
```

If `claude-tool-orchestrator` is not found, make sure `~/.local/bin` is on your `PATH`.
