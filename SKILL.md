# Publish a blog post to Kaveyl Wiki

## When to use

- Use this skill when an agent has to write, update, or archive a blog post or note in Kaveyl Wiki.
- Use it for a new post, for an update to an existing post, and for checking whether a post already exists before writing.
- Do not use it to change Kaveyl settings, sources, users, or tokens. Those steps stay in the browser app.

## What Kaveyl Wiki is

- Kaveyl Wiki is a self hosted wiki where every note stays a plain Markdown file in Git.
- Every save becomes a clean Git commit with the author attached.
- Agents connect through a built in MCP server or a REST API. Both use the same permissions as the app.
- A token acts only on behalf of its owner and never has more rights than that owner.

## What you need before you start

- Ask the user for the wiki base URL, for example `https://wiki.example.org`.
- Ask the user for the source name or source id where the post belongs, for example `docs`.
- Ask the user for an API token with `read`, `write`, and `mcp` scopes when the agent will write through MCP or REST.
- Create the token in the wiki under Settings, then AI and APIs, then API tokens.
- Treat the token as a secret. It starts with `kw_` and the wiki shows it only once.
- Store the token in a file with mode 600 or in the agent host secret store. Never put it in chat, in a code file, in a shell history entry, or in Git.
- Use one token per agent or per machine so each token can be revoked on its own.
- If no token exists yet and the user cannot create one, fall back to the browser route below.

## Choose your route

- Prefer MCP when the agent client speaks MCP. The client discovers the tools itself.
- Prefer REST when the work runs from a script, an automation, or a client without MCP.
- Use the browser route when there is no token, when the wiki is only reachable in a browser, or when MCP and REST are blocked.
- Use the direct file route only when the agent already has filesystem access to the source folder on the wiki server.

## Route A. Publish through MCP

- Point the MCP client at the Streamable HTTP endpoint `<wiki-base>/mcp`.
- Send the token on every request as `Authorization: Bearer <redacted>`.
- Start with `list_sources` and record the source id for the target source. Do not guess the id.
- Search first with `search` using the post title and a few keywords. Stop and ask the user when a post with the same topic already exists.
- Create a new post with `create_note` and pass the target source id, the folder, the title, and the full Markdown body.
- Update an existing post by reading it first with `read_note`, then calling `write_note` with the new full Markdown body and the `base_hash` from that read.
- Call `sync_source` after a write when the post has to appear in Git immediately. Otherwise the wiki commits after a short idle pause.
- Return the note path and the wiki URL to the user after you verify the post.

## Route B. Publish through REST

- Read the machine readable contract first at `<wiki-base>/api/v1/openapi.json`. It needs no authentication.
- Send the token on every request as `Authorization: Bearer <redacted>`.
- List sources with `GET /api/v1/sources` and record the id of the target source.
- Search first with `GET /api/v1/search?q=<query>`.
- Create a post with `POST /api/v1/notes/<source-id>` and a JSON body with `parent`, `title`, and `markdown`. The file name comes from the title.
- Read a post with `GET /api/v1/notes/<source-id>/<path>` and keep its `hash`.
- Replace a post with `PUT /api/v1/notes/<source-id>/<path>` and a JSON body with `markdown` and `baseHash` set to the hash from the read.
- Upload an image with `POST /api/v1/attachments/<source-id>` and a JSON body with `note`, `name`, and `contentBase64`. Use the returned `markdown` link in the post.
- Force a Git commit and sync with `POST /api/v1/sync/<source-id>` when the post has to be in Git immediately.
- URL encode each path segment. Keep the slashes between segments.

## Route C. Publish through the browser

- Open the wiki base URL in the browser and sign in. The sign in field asks for an email address, not a user name.
- Open the target source in the left tree and use New, then New note.
- Type the exact title first so the file name matches the title.
- Paste the full Markdown body that you drafted locally. Do not retype it from memory and do not shorten it silently.
- Wait for the editor to show Saved.
- Check the sync status in the left tree. It must read All sources in sync before you report success.
- Check the table of contents, the first line, and the last line of the saved post against your local draft.
- Return the note URL to the user only after those checks pass.

## Route D. Publish by writing the file directly

- Use this route only when the agent can write into the source folder on the wiki server.
- Write one Markdown file per post under the source folder, for example `docs/<folder>/<title>.md`.
- Keep the file name stable. Renaming a file breaks links that point at the old path unless the wiki repairs them.
- Let the wiki sync pick the file up, or trigger a sync from the app. Do not edit the wiki database directly.
- Verify in the app or through REST that the new file appears and that the sync status is clean.

## Write a good blog post

- Draft the full Markdown locally before you create anything in the wiki.
- Search the wiki first so you do not publish a duplicate.
- State in the draft when the content is a reconstruction from official docs rather than a recovered record, when that is true.
- Keep the title short and specific. Use the same title for the file name and for the first heading.
- Open with one short block that says who the post is for, which system it applies to, and what it covers.
- Put commands in fenced code blocks with the exact package names and versions you verified.
- Name each section with a numbered heading and keep the steps in order.
- Add a short troubleshooting section for the failures a reader will actually hit.
- Add a references section with the official sources you checked.
- Write links between notes as normal Markdown links with a path relative to the linking note. Kaveyl does not recognise double bracket wiki links.
- Use frontmatter tags only when the wiki instance uses them, and keep the tag names consistent with existing posts.

## Update an existing post

- Read the current post first and keep its `hash`.
- Merge your change into the current text instead of replacing the whole file from memory.
- Write the merged text back with the fresh `hash` as `baseHash` or `base_hash`.
- Read the post again after the write and compare the changed section.
- Report what changed in one sentence, with the note path and URL.

## Verify before you report success

- Confirm the post exists in the target source with the expected title and path.
- Confirm the first line and the last line match your local draft.
- Confirm the sync status is clean or that `sync_source` returned success.
- Confirm no other post was changed, moved, or deleted by your run.
- Report the note URL, the source name, and the title. Say plainly when any check failed.

## Troubleshoot

- A 401 means the token is missing, wrong, or expired. Check the header first, then ask the user for a fresh token.
- A 403 on MCP means the token has no `mcp` scope. A 403 on a write means the token has no `write` scope or the account has no write access to that source.
- A 403 with Origin not allowed means the call came from a third party web page. Call from outside the browser or from the same wiki address.
- A 404 can mean the note does not exist or the token cannot see it. Check the source id, the path encoding, and the account permissions before you conclude it is missing.
- A 409 means the file changed after your read. Read it again, merge your change into the new text, and write with the new hash.
- A client that finds no tools or asks for OAuth cannot send headers to an HTTP server. Connect through `mcp-remote` instead.
- An encrypted note returns a null Markdown body and refuses plain text writes. Do not try to work around it.
- A note that is open in the app and shows someone typing should wait a moment before you write to it.

## Security

- Never share a token with another agent, another machine, or another chat unless the user names that exact destination.
- Never log a token, print it in a report, or paste it into a URL.
- Revoke a token at once when it may have leaked. Create a replacement with the same scopes and update the agent config.
- Give an agent the narrowest access that still lets it do the job. A read only token cannot publish, and a token for one source should not write to another.
- Keep credentials out of this skill, out of example files, and out of Git history.

## Deployment notes

- The default Kaveyl address is the server root, for example `http://localhost:8093`, with REST at `/api/v1` and MCP at `/mcp`.
- When Kaveyl runs behind a subpath, prefix every path with that subpath. For example a wiki at `<host>/app` uses `<host>/app/api/v1/openapi.json` and `<host>/app/mcp`.
- Verify the subpath by opening `<host>/app/api/v1/openapi.json` in a browser. It returns the OpenAPI document without authentication when the prefix is right.
- A Kaveyl process started with a plain `nohup` can die when its terminal closes. Start it detached and add a watchdog that checks the health endpoint every 30 seconds when the host needs it to stay up.
- A watchdog does not survive a container restart. Restart the app by hand after a restart and verify the wiki opens again.

## Available connectors

- Use `muse.connector_search` to find other connectors and `muse.skill_search` to find related skills.
- If nothing here fits, look on the web for a maintained API or MCP server and set it up with [Custom Connectors and MCPs](/opt/muse/skills/custom-connector-setup/SKILL.md), or build a custom connector.

## Websites

- [Kaveyl Wiki on GitHub](https://github.com/kaveyl/wiki) for the source, the README, and the release notes.
- [Kaveyl REST API and MCP server](https://github.com/kaveyl/wiki/blob/main/docs/i18n/en/API.md) for the full endpoint and tool reference.
- [Kaveyl Wiki](https://kaveyl.app) for the project site and feature list.
