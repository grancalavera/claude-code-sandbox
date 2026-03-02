# Securely Passing Credentials to Docker Containers for GitHub Authentication

Research notes for configuring a Claude Code dev container with `gh` CLI authentication, Git operations (signing, push, pull), and admin access to authorised repos.

---

## Mechanisms for Getting Secrets into Containers

### Environment Variables

The simplest but weakest option. They show up in `docker inspect`, process listings, and logs. Fine for non-sensitive config, not great for tokens. That said, `gh` CLI natively reads `GH_TOKEN` from the environment, which makes this the path of least resistance.

### Docker Compose `secrets:`

Secrets are defined at the top level of your compose file and mounted as files at `/run/secrets/<name>` inside the container. They live on a tmpfs (in-memory filesystem), so they don't persist to disk in the container's writable layer. This is what Docker recommends for Compose-based workflows.

The limitation: it requires Compose or Swarm — plain `docker run` doesn't support it.

```yaml
services:
  myapp:
    image: myapp:latest
    secrets:
      - gh_token

secrets:
  gh_token:
    file: ./gh_token.txt
```

### Bind-Mounting a Host File

You can mount a file from the host (e.g., `~/.config/gh/hosts.yml`) directly into the container. Simple, but the file permissions and host-side security are entirely on you.

### External Secret Managers

Vault, AWS Secrets Manager, etc. The gold standard for production, but overkill for a local dev sandbox.

### Docker Pass

A helper that stores secrets in your local OS keychain (macOS Keychain, Windows Credential Manager) and injects them into containers:

```bash
docker run -e GITHUB_TOKEN=se://GH_TOKEN -dt --name demo myimage
```

### BuildKit Secret Mounts (Build Time Only)

For secrets needed during `docker build` (not runtime). Temporarily mounted for a single `RUN` instruction, never written into the final image:

```dockerfile
# syntax=docker/dockerfile:1
RUN --mount=type=secret,id=github_token \
    cat /run/secrets/github_token | gh auth login --with-token
```

```bash
docker build --secret id=github_token,env=GH_TOKEN .
```

---

## The Three Things You Need Inside the Container

### 1. `gh` CLI Authentication

`gh` supports two approaches in headless/container environments:

**`GH_TOKEN` env var** — `gh` reads this automatically. Works with both classic and fine-grained PATs. No further setup needed.

**`gh auth login --with-token`** — Pipe a token into this during container provisioning. You'll want `--insecure-storage` since there's no system keyring inside the container. This writes to `~/.config/gh/hosts.yml`.

### 2. Git Push/Pull (HTTPS)

If you're using HTTPS (which a firewall-restricted container implies), `gh` can act as a Git credential helper:

```bash
gh auth setup-git
```

This configures Git to use `gh` for HTTPS authentication. Once `gh` is authenticated, `git push/pull` just works — no separate credential needed.

### 3. Commit Signing

**SSH signing (recommended for containers):**

Mount the SSH agent socket from the host into the container, then configure Git:

```bash
git config --global gpg.format ssh
git config --global user.signingkey "ssh-ed25519 AAAA... your-key"
git config --global commit.gpgsign true
```

**GPG signing:** Requires `gnupg2` in the container and either importing your key or forwarding the GPG agent socket. More fiddly than SSH signing.

---

## Token Strategy

**Use a fine-grained PAT** as your primary token. GitHub recommends them over classic PATs:

- Scoped to specific repositories (restrict to only the repos Claude should touch)
- Granular permissions (e.g., `contents: write` for push, `pull_requests: write` for PR management, `administration: write` only for repos that need admin ops)
- Mandatory expiration — forces rotation
- Organisation owners can require approval for tokens targeting org repos

**Caveat:** Fine-grained PATs can't write to public repos you don't own. If you need that, you'd need a classic PAT with `repo` scope for those specific operations.

---

## Claude Code Isolation & Secret Leakage

### The Fundamental Trade-Off

If Claude is running `gh` commands, it fundamentally needs the token (either as an env var or accessible file). You can't both give Claude `gh` access and hide the token from it.

### What You Can Do

**Scope the token tightly** — Fine-grained PAT, limited repos, limited permissions.

**Short expiration + rotation** — Limits the blast radius of any leak.

**Network firewall** — This is your strongest defence. Even if Claude "sees" the token, it can only talk to GitHub, NPM, Anthropic, Sentry, and Statsig. It can't POST it to an attacker's server.

**`permissions.deny`** — You can deny Claude Code access to specific paths (e.g., `Read(/run/secrets/**)`). But if the token is already in `GH_TOKEN` in the environment, denying file reads doesn't help.

**Monitor usage** — GitHub's audit log tracks all token activity.

### Available Claude Code Sandbox Layers

- **Permission-based denylists:** `permissions.deny` blocks access to specific files/paths
- **OS-level enforcement:** Running Claude Code as a separate user with restrictive permissions
- **Container/filesystem isolation:** Mounting `/dev/null` over `.env` makes the file invisible
- **Network isolation:** Restricting outbound connections to approved domains only (via iptables/bubblewrap)

---

## Concrete Recommendation for Your Setup

```yaml
services:
  claude-code:
    build:
      context: .devcontainer
      dockerfile: Dockerfile
      args:
        TZ: ${TZ:-Europe/London}
    cap_add:
      - NET_ADMIN
      - NET_RAW
      - SYS_ADMIN
    shm_size: 2gb
    user: node
    working_dir: /workspace
    volumes:
      - .:/workspace:delegated
      - claude-code-bashhistory:/commandhistory
      - claude-code-config:/home/node/.claude
      # Forward SSH agent for commit signing
      - ${SSH_AUTH_SOCK:-/dev/null}:/tmp/ssh-agent.sock:ro
    environment:
      CLAUDE_CONFIG_DIR: /home/node/.claude
      POWERLEVEL9K_DISABLE_GITSTATUS: "true"
      SSH_AUTH_SOCK: /tmp/ssh-agent.sock
    secrets:
      - gh_token
    stdin_open: true
    tty: true

secrets:
  gh_token:
    file: ${GH_TOKEN_FILE:-~/.gh-token}

volumes:
  claude-code-bashhistory:
  claude-code-config:
```

Then in your `postCreateCommand` or entrypoint:

```bash
# Auth gh from the secret file
export GH_TOKEN=$(cat /run/secrets/gh_token)
gh auth setup-git  # configures git to use gh for HTTPS creds
```

Store your token in `~/.gh-token` on the host (with `chmod 600`), and set `GH_TOKEN_FILE` if you want a different path.

---

## Sources

- [Docker Compose Secrets](https://docs.docker.com/compose/how-tos/use-secrets/)
- [Docker Build Secrets (BuildKit)](https://docs.docker.com/build/building/secrets/)
- [gh CLI in Docker containers discussion](https://github.com/cli/cli/discussions/7611)
- [gh CLI auth in devcontainers](https://github.com/cli/cli/discussions/3226)
- [Docker Secrets guide (Spacelift)](https://spacelift.io/blog/docker-secrets)
- [Secrets in Docker (GitGuardian)](https://blog.gitguardian.com/how-to-handle-secrets-in-docker/)
- [Claude Code sandboxing](https://www.anthropic.com/engineering/claude-code-sandboxing)
- [claude-code-sandbox for macOS](https://github.com/neko-kai/claude-code-sandbox)
