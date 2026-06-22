# freemclaude

Run [Claude Code](https://docs.claude.com/en/docs/claude-code) against [FreeModel](https://freemodel.dev)'s Anthropic-compatible API.

Install once with a single command, enter your FreeModel API key once (it asks you interactively if you haven't included it yet), and from then on just run `freemclaude` — it sets the base URL/API key and launches `claude` for you.

> **Note:** Requires the `claude` CLI to already be installed ([instructions](https://docs.claude.com/en/docs/claude-code)).

## Install (one command)

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/<YOUR_GITHUB_USERNAME>/freemclaude/main/install.sh | bash
```

Installs a single `freemclaude` script into `~/.local/bin`. If that directory isn't on your `PATH`, the installer prints the line to add.

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/<YOUR_GITHUB_USERNAME>/freemclaude/main/install.ps1 | iex
```

Installs `freemclaude` into `%LOCALAPPDATA%\Programs\freemclaude` and adds it to your user `PATH`. Open a **new** terminal afterward.

---

## Use

First run asks for your FreeModel API key (hidden input) and saves it:

```bash
freemclaude
```

Every run after that just works — same key, no prompt. Any arguments pass straight through to `claude`:

```bash
freemclaude "refactor this module"
freemclaude --help
```

### Ways to provide the key

The key is resolved in this order:

1. `freemclaude config <KEY>` — set it inline, no prompt.
2. The stored config file — set on a previous run.
3. `FREEMODEL_API_KEY` environment variable — used and saved for next time.
4. Interactive prompt — asked for automatically if none of the above is set.

## Manage your key

```bash
freemclaude change-key        # change the stored key (interactive prompt)
freemclaude change-key <KEY>  # change the key without a prompt
freemclaude reset             # delete the stored key
```

`config`, `set-key`, and `change` are accepted as aliases for `change-key`.

| Platform        | Where the key is stored                            |
| --------------- | -------------------------------------------------- |
| macOS / Linux   | `~/.config/freemclaude/config` (perms `600`)       |
| Windows         | `%APPDATA%\freemclaude\config` (ACL: you only)     |

It is stored in plaintext on your machine. Treat it like any other local credential.

## What it sets

```sh
ANTHROPIC_BASE_URL="https://cc.freemodel.dev"
ANTHROPIC_AUTH_TOKEN="<your FreeModel API key>"
```

Then runs: `claude --dangerously-skip-permissions "$@"`

If you are on FreeModel's T1 tier, you can customize the base URL by exporting the environment variable:
```sh
export ANTHROPIC_BASE_URL="https://api-cc.freemodel.dev"
```

## Uninstall

**macOS / Linux**

```bash
rm ~/.local/bin/freemclaude
rm -rf ~/.config/freemclaude
```

**Windows (PowerShell)**

```powershell
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Programs\freemclaude"
Remove-Item -Recurse -Force "$env:APPDATA\freemclaude"
```
