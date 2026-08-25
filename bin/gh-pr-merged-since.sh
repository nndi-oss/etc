#!/usr/bin/env bash

# export-merged-prs-md.sh
#
# Usage:
#   ./export-merged-prs-md.sh <org> 2026-01-01 output.md

set -euo pipefail

ORG="${1:-}"
SINCE_DATE="${2:-2026-01-01}"
OUTPUT="${3:-merged-prs.md}"

if [[ -z "$ORG" ]]; then
  echo "Usage: $0 <org> [since-date] [output.md]"
  exit 1
fi

SINCE_ISO="${SINCE_DATE}T00:00:00Z"

echo "# Merged PRs for $ORG since $SINCE_DATE" > "$OUTPUT"
echo >> "$OUTPUT"

append_pr() {
  local repo="$1"
  local number="$2"
  local title="$3"
  local url="$4"
  local author="$5"
  local mergedAt="$6"
  local body="$7"

  {
    echo "## $repo PR #$number — $title"
    echo
    echo "- URL: $url"
    echo "- Author: $author"
    echo "- Merged At: $mergedAt"
    echo
    echo "### Description"
    echo
    printf '%s\n' "$body"
    echo
    echo "---"
    echo
  } >> "$OUTPUT"
}

echo "Fetching repositories for org: $ORG"

repos=$(gh repo list "$ORG" \
  --limit 10000 \
  --json nameWithOwner \
  --jq '.[].nameWithOwner')

for repo in $repos; do
  echo "Processing $repo..."

  page=1

  while :; do
    response=$(gh api \
      "repos/$repo/pulls?state=closed&sort=updated&direction=desc&per_page=100&page=$page")

    count=$(echo "$response" | jq 'length')

    if [[ "$count" -eq 0 ]]; then
      break
    fi

    echo "$response" | jq -c '.[]' | while read -r pr; do
      mergedAt=$(echo "$pr" | jq -r '.merged_at // empty')

      # skip unmerged PRs
      if [[ -z "$mergedAt" ]]; then
        continue
      fi

      # stop early if PRs are older than cutoff (API sorted DESC)
      if [[ "$mergedAt" < "$SINCE_ISO" ]]; then
        continue
      fi

      number=$(echo "$pr" | jq -r '.number')
      title=$(echo "$pr" | jq -r '.title')
      url=$(echo "$pr" | jq -r '.html_url')
      author=$(echo "$pr" | jq -r '.user.login // "unknown"')
      body=$(echo "$pr" | jq -r '.body // ""')

      append_pr "$repo" "$number" "$title" "$url" "$author" "$mergedAt" "$body"
    done

    ((page++))
  done
done

echo "Done → $OUTPUT"