#!/bin/bash
# Publish a blog post to Kaveyl Wiki through the REST API.
# Usage: KAVEYL_WIKI_TOKEN=<token> ./rest-blog.sh <source-id> <title> <markdown-file>
# The token must come from the environment, never from the command line.
# Replace https://wiki.example.org with your wiki base URL.
# If your wiki runs behind a subpath, use https://wiki.example.org/app/api/v1
set -eu
BASE="${KAVEYL_WIKI_BASE:-https://wiki.example.org/api/v1}"
SRC="${1:?source id required}"
TITLE="${2:?title required}"
FILE="${3:?markdown file required}"
HDR=$(mktemp); chmod 600 "$HDR"; trap 'rm -f "$HDR"' EXIT
printf 'Authorization: Bearer %s\n' "$KAVEYL_WIKI_TOKEN" > "$HDR"
jq -n --arg title "$TITLE" --rawfile markdown "$FILE" \
  '{parent: "", title: $title, markdown: $markdown}' |
  curl -s -X POST -H @"$HDR" -H 'content-type: application/json' --data @- "$BASE/notes/$SRC"
echo
curl -s -X POST -H @"$HDR" "$BASE/sync/$SRC"
echo
echo "Done. Check the returned path in the wiki."
