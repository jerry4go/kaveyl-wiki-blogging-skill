# Kaveyl Wiki Blogging Skill

A generic skill that teaches any AI agent how to publish a blog post to [Kaveyl Wiki](https://github.com/kaveyl/wiki).

Kaveyl Wiki is a self-hosted wiki where every note stays a plain Markdown file in Git. Every save becomes a clean Git commit. Agents connect through its built-in MCP server or its REST API, with the same permissions as the app.

## What this skill covers

- **Route A — MCP (preferred for agents):** `list_sources`, `search`, `create_note`, `read_note`, `write_note`, `sync_source`
- **Route B — REST (preferred for scripts):** `GET /api/v1/sources`, `POST /api/v1/notes/{source}`, `PUT /api/v1/notes/{source}/{path}`, `POST /api/v1/sync/{source}`
- **Route C — Browser UI (fallback, no token needed):** sign in with email, New note in the target source, paste the full Markdown draft, wait for Saved, check "All sources in sync"
- **Route D — Direct file:** write one `.md` file into the source folder on the wiki server, let the wiki sync pick it up

It also covers: searching first to avoid duplicates, drafting locally, updating with `baseHash` / `base_hash` and handling 409 conflicts, verifying first/last lines and sync status, and troubleshooting 401 / 403 / 404 / 409.

## Files

| File | What it is |
| --- | --- |
| `SKILL.md` | The skill itself. Copy this whole folder into your agent's skills directory. |
| `skill.yaml` | Muse skill descriptor (name, title, description, category). |
| `examples/mcp.json` | MCP client config for Cursor / LM Studio and other `mcpServers` clients. |
| `examples/claude-code.sh` | Claude Code command to add the MCP server without putting the token in shell history. |
| `examples/rest-blog.sh` | Bash script that creates a post through the REST API. |
| `examples/blog-post.md` | A sample blog post draft in the format this skill expects. |
| `.gitignore` | Keeps `.env` files and token files out of Git. |

## Quick start

### 1. Create a token

In Kaveyl Wiki: **Settings → AI & APIs → API tokens** → choose a name, scopes `read`, `write`, `mcp` → Create token.

The token starts with `kw_` and is shown only once. Store it in a file with mode `600`, for example `~/.kaveyl-wiki.env`, or in your agent host's secret store. Never commit it.

### 2. Connect your agent (MCP)

For Claude Code:

```bash
read -rs KAVEYL_WIKI_TOKEN
claude mcp add --transport http kaveyl-wiki https://wiki.example.org/mcp --header "Authorization: Bearer $KAVEYL_WIKI_TOKEN"
```

For Cursor / LM Studio, copy `examples/mcp.json` and replace `https://wiki.example.org/mcp` and the token.

For Claude Desktop and other stdio-only clients, use `mcp-remote` as shown in `examples/mcp.json`.

### 3. Publish a post

Ask the agent to follow `SKILL.md`:

1. `list_sources` / `GET /api/v1/sources` → record the source id
2. `search` for the title first
3. `create_note` / `POST /api/v1/notes/{source}` with the full Markdown draft
4. `sync_source` / `POST /api/v1/sync/{source}` when the post must be in Git now
5. Verify title, path, first line, last line, and sync status, then return the note URL

## Subpath deployments

If your Kaveyl runs behind a subpath, prefix every path with it. A wiki at `<host>/app` uses `<host>/app/api/v1/openapi.json` and `<host>/app/mcp`. Verify the prefix by opening the `openapi.json` URL — it returns the OpenAPI document without authentication when the prefix is right.

## How this skill was built

It was distilled from a real deployment: Kaveyl Wiki 0.2.13 on a free Uppcoder Spark stack, with a local-folder source named `docs`, published through the browser UI (verified 2026-11-11 with a Debian 13 Fcitx5 guide), and cross-checked against the official Kaveyl API documentation (`docs/i18n/en/API.md`, API version 1, as of 2026-10-15).

The MCP and REST routes in this skill come from that official documentation. The browser route is the one actually used in that deployment, because no MCP token had been created there yet.

## Security

- One token per agent or machine, so each can be revoked on its own.
- Never put a token in chat, code, shell history, or Git.
- Revoke a token at once if it may have leaked.

## License

MIT. Kaveyl Wiki itself is AGPL-3.0 — see [kaveyl/wiki](https://github.com/kaveyl/wiki).
