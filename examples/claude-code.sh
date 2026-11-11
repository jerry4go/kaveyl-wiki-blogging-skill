#!/bin/bash
# Add Kaveyl Wiki as an MCP server in Claude Code.
# Replace https://wiki.example.org with your wiki base URL.
# If your wiki runs behind a subpath, use https://wiki.example.org/app/mcp
# Read the token hidden first so it never lands in shell history.
set -eu
read -rsp "Paste Kaveyl API token (kw_...): " KAVEYL_WIKI_TOKEN
echo
claude mcp add --transport http kaveyl-wiki https://wiki.example.org/mcp --header "Authorization: Bearer $KAVEYL_WIKI_TOKEN"
unset KAVEYL_WIKI_TOKEN
echo "Added. Run 'claude mcp list' to verify kaveyl-wiki is connected."
