# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a DevContainer-based sandbox environment for Claude Code development and testing. The repository is primarily configured for containerized development with security restrictions and firewall controls.

## Architecture

The environment is built around:
- **DevContainer Configuration**: Node.js 24-based development environment with zsh shell
- **Security Layer**: Network firewall that restricts outbound connections to approved domains only
- **Development Tools**: Pre-configured with ESLint, Prettier, GitLens, and Git utilities
- **Container Security**: Runs with NET_ADMIN and NET_RAW capabilities for firewall management

## DevContainer Environment

The development environment runs in a container with:
- Node.js 24 runtime
- Zsh shell with powerline10k theme and fzf integration
- Git Delta for enhanced diffs
- Claude Code CLI pre-installed globally (`claude-code`)
- Network restrictions via iptables firewall
- GitHub CLI (`gh`) for GitHub operations
- Additional tools: `jq`, `aggregate`, `fzf`, `dnsutils`

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
- Allows only specific domains: GitHub, NPM registry, Anthropic API, Sentry, and Statsig
- Resolves domain IPs dynamically and maintains IP sets using `ipset`
- Verifies firewall rules are working correctly on startup
- Uses GitHub's meta API to fetch current IP ranges
- Runs firewall initialization with sudo privileges during container startup

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

Any attempts to access other domains will be blocked by the firewall. The firewall verification process runs during container startup and confirms that blocked domains (like example.com) are unreachable while allowed domains remain accessible.