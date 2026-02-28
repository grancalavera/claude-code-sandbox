# Claude Code Yolo Sandbox

A secure DevContainer environment for Claude Code development and testing.

Based on https://github.com/anthropics/claude-code/tree/main/.devcontainer

## Overview

This repository provides a containerized development environment with network security restrictions, designed for safe experimentation with Claude Code.

## Features

- **Secure Environment**: Network firewall restricts outbound connections to approved domains only
- **Development Ready**: Pre-configured with Node.js 24, zsh shell, and development tools
- **Claude Code Integration**: Claude Code CLI pre-installed and ready to use
- **Git Configuration**: Auto-configured with user settings and best practices
- **Browser Testing**: System Chromium pre-installed for Playwright/headless browser testing

## Getting Started

1. Open this repository in a DevContainer-compatible environment (VS Code with Dev Containers extension)
2. The container will automatically build and configure the environment
3. Start using Claude Code with the `claude-code` command

## Security

The environment includes strict network controls:

- Outbound connections limited to domains listed in `.devcontainer/allowed-domains.conf`
- All other domains are blocked by default
- Firewall rules are automatically configured on container startup
- To modify allowed domains, edit `.devcontainer/allowed-domains.conf` and rebuild the container

## Development Environment

- **Runtime**: Node.js 24
- **Shell**: Zsh with powerline10k theme
- **Tools**: ESLint, Prettier, Git Delta, fzf, GitHub CLI
- **Browser**: System Chromium (use `$CHROMIUM_PATH` with Playwright)
- **User**: Runs as `node` user (non-root)

## Network Access

Due to security restrictions, only these domains are accessible:

- `github.com` and `api.github.com`
- `registry.npmjs.org`
- `api.anthropic.com`
- `sentry.io`
- `statsig.anthropic.com` and `statsig.com`
- `playwright.azureedge.net`
