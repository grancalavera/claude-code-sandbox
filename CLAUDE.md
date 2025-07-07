# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a DevContainer-based sandbox environment for Claude Code development and testing. The repository is primarily configured for containerized development with security restrictions and firewall controls.

## Architecture

The environment is built around:
- **DevContainer Configuration**: Node.js 24-based development environment with zsh shell
- **Security Layer**: Network firewall that restricts outbound connections to approved domains only
- **Development Tools**: Pre-configured with ESLint, Prettier, and Git utilities

## DevContainer Environment

The development environment runs in a container with:
- Node.js 24 runtime
- Zsh shell with powerline10k theme
- Git Delta for enhanced diffs
- Claude Code CLI pre-installed globally
- Network restrictions via iptables firewall

## Security Features

The environment includes a strict firewall configuration (`init-firewall.sh`) that:
- Blocks most outbound connections by default
- Allows only specific domains: GitHub, NPM registry, Anthropic API, Sentry, and Statsig
- Resolves domain IPs dynamically and maintains IP sets
- Verifies firewall rules are working correctly

## Development Commands

Since this is a sandbox environment, there are no specific build, test, or lint commands defined. The Claude Code CLI is available globally as `claude-code`.

## Git Configuration

The environment auto-configures Git with:
- Email: leoncoto@gmail.com
- Name: Leon Coto
- Pull rebase enabled
- Auto-setup remote on push
- Rerere (reuse recorded resolution) enabled

## Network Restrictions

Due to the firewall configuration, only the following domains are accessible:
- GitHub (api.github.com, github.com)
- NPM registry (registry.npmjs.org)
- Anthropic API (api.anthropic.com)
- Sentry (sentry.io)
- Statsig (statsig.anthropic.com, statsig.com)

Any attempts to access other domains will be blocked by the firewall.