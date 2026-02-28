# Network Investigation: How Claude Code Web Search Works

## Motivation

This sandbox environment uses a strict firewall that only allows outbound connections to a whitelist of domains (see `.devcontainer/allowed-domains.conf`). The concern was whether web search in Claude Code requires direct access to external search engines or other third-party domains. If it does, those domains would need to be added to the allowlist — but since the search provider isn't documented, we'd be guessing. If search is handled entirely server-side through `api.anthropic.com`, then the existing allowlist is sufficient and web search works without any additional domains.

## Method

Captured DNS traffic inside the container using:

```bash
sudo tcpdump -i any -n -v 'udp port 53' -l 2>&1
```

The `-v` flag is required — without it, tcpdump only shows IPs, not domain names. Docker's embedded DNS (`127.0.0.11`) intercepts outbound queries, so only responses are visible, not the original queries.

## Findings

### Web search goes through Anthropic's API

When Claude Code performs a web search, traffic only goes to `api.anthropic.com`. Claude Code sends the search request to Anthropic's API, which performs the search server-side and returns results. There are no direct requests to any search engine.

The official [web search tool documentation](https://platform.claude.com/docs/en/agents-and-tools/tool-use/web-search-tool) describes the flow as: "The API executes the searches and provides Claude with the results." The tool type is `server_tool_use` and results include `encrypted_content` fields, both consistent with server-side execution. However, the docs never explicitly name a search provider or state that searches run on Anthropic's servers — the backend implementation is opaque. Our tcpdump capture is the closest thing to concrete confirmation that no third-party search engine is contacted directly by the client.

**Implication for the sandbox firewall**: Web search works with only `api.anthropic.com` in the allowlist. No additional domains are needed. If Anthropic ever changes the architecture to require client-side requests to a search provider, web search would break — at which point the tcpdump method described here can be used to identify which domains to add.

### npm background traffic

`registry.npmjs.org` DNS lookups happen while Claude Code is running — npm background checks (update notifications, etc.), not an independent process. They stop when Claude Code is stopped.

### Datadog telemetry

`http-intake.logs.us5.datadoghq.com` DNS queries appear from Claude Code or one of its dependencies. The firewall blocks the actual TCP connection since Datadog is not in the allowed domains list. DNS resolves (port 53 is allowed) but `nc -zv 34.149.66.137 443 -w5` times out, confirming the firewall works at the IP level.
