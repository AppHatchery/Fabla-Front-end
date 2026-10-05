#!/usr/bin/env bash
# Keeps one standing GitHub issue up to date with the release's results.
#
# Used by Complexity_Checker.yml. The issue is found by its label, open or
# closed. Each release rewrites the title and description with the latest
# report and adds a comment. The comment is what notifies people: GitHub sends
# nothing for an edited description. The first run opens the issue and assigns
# it, which notifies the assignees instead.
#
# If the check broke, the description keeps the last release that did run and
# only the comment changes. A clean release leaves a closed issue closed;
# anything else reopens it.
#
# Reads: GH_TOKEN, GITHUB_REPOSITORY, ISSUE_LABEL, ISSUE_ASSIGNEES, RELEASE_TAG,
#        RELEASE_AUTHOR, RUN_URL, AUDIT_THRESHOLD, and when earlier steps set
#        them PREVIOUS_TAG, AUDIT_CODE and AUDIT_RESULT
set -euo pipefail

previous_tag=${PREVIOUS_TAG:-}
audit_code=${AUDIT_CODE:-}

if [ -n "$previous_tag" ]; then
  since=" since \`$previous_tag\`"
else
  since=" (no earlier release to compare with)"
fi
# "RESULT: fail — 2 unit(s) new or worsened" -> 2
count=$(printf '%s' "${AUDIT_RESULT:-}" | sed -n 's/^RESULT: fail — \([0-9]*\).*/\1/p')

# Anything but 0 or 1, including no code because an earlier step failed, means
# the check itself broke.
rewrite=true
case "$audit_code" in
  0)
    title="[COMPLEXITY] $RELEASE_TAG: nothing new or worse"
    summary="No function in \`$RELEASE_TAG\` crossed complexity $AUDIT_THRESHOLD or got worse$since."
    ;;
  1)
    title="[COMPLEXITY] $RELEASE_TAG: ${count:-some} function(s) new or worse"
    summary="${count:-Some} function(s) in \`$RELEASE_TAG\` crossed complexity $AUDIT_THRESHOLD or got worse$since."
    ;;
  *)
    title="[COMPLEXITY] $RELEASE_TAG: check could not run"
    summary="The complexity check for \`$RELEASE_TAG\` stopped before producing a result. The run log has the error."
    rewrite=false
    ;;
esac

{
  echo "$summary"
  echo
  echo "Last updated for \`$RELEASE_TAG\` · [full report]($RUN_URL)"
  if [ "$audit_code" = 1 ] && [ -f complexity-report.md ]; then
    echo
    # Only the new-or-worse section: it starts at the first tier heading and
    # ends where the collapsed context begins.
    awk '/^### /{p=1} /^<details>/{exit} p' complexity-report.md
  fi
  echo
  echo "---"
  echo "_Kept up to date by the Complexity Checker workflow. Each release replaces this description and adds a comment._"
} > issue-body.md

{
  echo "${RELEASE_AUTHOR:+@$RELEASE_AUTHOR }$summary"
  echo
  echo "[Full report]($RUN_URL)"
} > issue-comment.md

gh label create "$ISSUE_LABEL" --repo "$GITHUB_REPOSITORY" --force \
  --color 5319e7 --description "Release complexity report from the Complexity Checker workflow"

# Newest first, open or closed, so a closed issue is reused rather than a
# second one opened.
found=$(gh issue list --repo "$GITHUB_REPOSITORY" --label "$ISSUE_LABEL" \
  --state all --limit 1 --json number,state --jq '.[] | "\(.number) \(.state)"')

if [ -z "$found" ]; then
  gh issue create --repo "$GITHUB_REPOSITORY" --title "$title" \
    --body-file issue-body.md --label "$ISSUE_LABEL" --assignee "$ISSUE_ASSIGNEES"
  exit 0
fi

number=${found%% *}
state=${found#* }
if [ "$rewrite" = true ]; then
  gh issue edit "$number" --repo "$GITHUB_REPOSITORY" --title "$title" --body-file issue-body.md
fi
if [ "$state" = CLOSED ] && [ "$audit_code" != 0 ]; then
  gh issue reopen "$number" --repo "$GITHUB_REPOSITORY"
fi
gh issue comment "$number" --repo "$GITHUB_REPOSITORY" --body-file issue-comment.md
