#!/usr/bin/env bash

set -euo pipefail

REPO="${1:-}"
OUTPUT="${2:-comments.md}"

if [[ -z "$REPO" ]]; then
  echo "Usage: $0 owner/repo [output.md]"
  exit 1
fi

echo "Fetching PRs from $REPO..."

# Common bot patterns
BOT_REGEX='(dependabot|renovate|github-actions|codecov|pre-commit-ci|imgbot|snyk|semantic-release|copilot|bot])'

# Initialize output file
{
  echo "# Pull Request Comments for $REPO"
  echo
  echo "_Generated on $(date)_"
  echo
} > "$OUTPUT"

append_comment() {
  local date="$1"
  local user="$2"
  local ctx="$3"
  local body="$4"

  # Skip empty bodies
  if [[ -z "$(echo "$body" | tr -d '[:space:]')" ]]; then
    return
  fi

  # Skip known bots
  if [[ "$user" =~ $BOT_REGEX ]]; then
    return
  fi

  {
    echo "## $date – $user"
    echo
    echo "*$ctx*"
    echo
    printf '%s\n' "$body"
    echo
    echo "---"
    echo
  } >> "$OUTPUT"
}

pr_numbers=$(gh pr list \
  --repo "$REPO" \
  --state all \
  --limit 1000 \
  --json number \
  --jq '.[].number')

for pr in $pr_numbers; do
  echo "Processing PR #$pr..."

  #
  # PR Description
  #
  while IFS=$'\t' read -r date user ctx body; do
    append_comment "$date" "$user" "$ctx" "$body"
  done < <(
    gh pr view "$pr" \
      --repo "$REPO" \
      --json body,createdAt,author \
      --jq "[
        .createdAt,
        (.author.login // \"unknown\"),
        \"PR #$pr Description\",
        (.body // \"\")
      ] | @tsv"
  )

  #
  # Issue comments
  #
  while IFS=$'\t' read -r date user ctx body; do
    append_comment "$date" "$user" "$ctx" "$body"
  done < <(
    gh pr view "$pr" \
      --repo "$REPO" \
      --json comments \
      --jq ".comments[]? | [
        .createdAt,
        (.author.login // \"unknown\"),
        \"PR #$pr Comment\",
        (.body // \"\")
      ] | @tsv"
  )

  #
  # Review comments
  #
  while IFS=$'\t' read -r date user ctx body; do
    append_comment "$date" "$user" "$ctx" "$body"
  done < <(
    gh api \
      "repos/$REPO/pulls/$pr/comments" \
      --paginate \
      --jq ".[] | [
        .created_at,
        (.user.login // \"unknown\"),
        \"PR #$pr Review Comment\",
        (.body // \"\")
      ] | @tsv"
  )
done

echo "Comments saved to $OUTPUT"