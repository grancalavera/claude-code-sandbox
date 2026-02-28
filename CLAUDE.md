# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a containerized sandbox environment for Claude Code development and testing. The container runtime is defined in `docker-compose.yml` (the single source of truth), with VS Code devcontainer support via a thin `.devcontainer/devcontainer.json` wrapper that delegates to compose.

## Architecture

The environment is built around:
- **Docker Compose**: Primary runtime configuration (`docker-compose.yml`) — build, volumes, capabilities, env vars
- **DevContainer Wrapper**: `.devcontainer/devcontainer.json` references compose for VS Code "Reopen in Container" support
- **Security Layer**: Network firewall that restricts outbound connections to approved domains only
- **Development Tools**: Pre-configured with ESLint, Prettier, GitLens, and Git utilities
- **Container Security**: Runs with NET_ADMIN, NET_RAW, and SYS_ADMIN capabilities for firewall management and Chrome sandbox
- **Browser Testing**: System Chromium pre-installed for Playwright/headless browser testing

## DevContainer Environment

The development environment runs in a container with:
- Node.js 24 runtime
- Zsh shell with powerline10k theme and fzf integration
- Git Delta for enhanced diffs
- Claude Code CLI pre-installed globally (`claude-code`)
- Network restrictions via iptables firewall
- GitHub CLI (`gh`) for GitHub operations
- System Chromium for Playwright/headless browser testing
- Additional tools: `jq`, `fzf`, `dnsutils`

## VS Code Integration

The environment is configured with:
- **Extensions**: ESLint, Prettier, GitLens
- **Auto-formatting**: Format on save with Prettier
- **ESLint**: Automatic fixes on save
- **Terminal**: Default zsh shell with powerline10k theme
- **History**: Persistent command history across container restarts

## Security Features

The environment includes a strict firewall configuration (`init-firewall.sh`) that:
- Blocks most outbound connections by default
- Allows only domains listed in `.devcontainer/allowed-domains.conf`
- Resolves domain IPs dynamically and maintains IP sets using `ipset`
- Verifies firewall rules are working correctly on startup
- Runs firewall initialization with sudo privileges during container startup

To modify allowed domains, edit `.devcontainer/allowed-domains.conf` and rebuild the container.

## Running the Environment

### Via Docker Compose (CLI)

```bash
docker compose up -d
docker compose exec claude-code zsh
```

On first start, the entrypoint script automatically runs git setup and firewall initialization (tracked by a `/home/node/.setup-done` marker file).

### Via VS Code DevContainer

Use "Reopen in Container" — VS Code reads `.devcontainer/devcontainer.json`, which delegates to `docker-compose.yml` for build/runtime config. The `postCreateCommand` handles git and firewall setup.

## Development Commands

Since this is a sandbox environment, there are no specific build, test, or lint commands defined. The Claude Code CLI is available globally as `claude-code`.

## Git Configuration

The environment auto-configures Git with:
- Email: leoncoto@gmail.com
- Name: Leon Coto
- Pull rebase enabled
- Auto-setup remote on push
- Rerere (reuse recorded resolution) enabled
- Default branch: main
- Enhanced diff viewer with Git Delta

## Environment Variables

Key environment variables set in the container:
- `CLAUDE_CONFIG_DIR`: `/home/node/.claude`
- `DEVCONTAINER`: `true`
- `NPM_CONFIG_PREFIX`: `/usr/local/share/npm-global`
- `CHROMIUM_PATH`: `/usr/bin/chromium`
- `PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD`: `1`
- `POWERLEVEL9K_DISABLE_GITSTATUS`: `true`

## Volume Mounts

The container uses the following volume mounts:
- **Command History**: Persistent bash history stored in `claude-code-bashhistory` volume
- **Claude Config**: User's Claude configuration from `~/.claude` (bind mount)
- **Workspace**: Project files from local workspace (bind mount)

## Network Restrictions

Due to the firewall configuration, only the following domains are accessible:
- GitHub (api.github.com, github.com)
- NPM registry (registry.npmjs.org)
- Anthropic API (api.anthropic.com)
- Sentry (sentry.io)
- Statsig (statsig.anthropic.com, statsig.com)
- Playwright CDN (playwright.azureedge.net)

Any attempts to access other domains will be blocked by the firewall. The firewall verification process runs during container startup and confirms that blocked domains (like example.com) are unreachable while allowed domains remain accessible.

## Playwright / Headless Browser

The container includes system Chromium for headless browser testing with Playwright:

- Chromium is installed via apt (no Playwright CDN download needed)
- `CHROMIUM_PATH` env var points to `/usr/bin/chromium`
- `PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1` prevents Playwright from downloading its own browsers
- `SYS_ADMIN` capability and 2GB shared memory (`shm_size`) support Chrome's sandbox
- When launching Chromium via Playwright, pass the executable path explicitly:
  ```js
  chromium.launch({ executablePath: process.env.CHROMIUM_PATH })
  ```
- Run `./test-playwright.sh` to verify the setup works