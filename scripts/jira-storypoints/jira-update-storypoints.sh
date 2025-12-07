#!/bin/bash

# jira-update-storypoints.sh
# Updates story point estimates for one or more Jira tickets
#
# Usage:
#   jira-update-storypoints.sh ISSUE-KEY POINTS [ISSUE-KEY POINTS ...]
#
# Examples:
#   jira-update-storypoints.sh PROJ-123 3
#   jira-update-storypoints.sh PROJ-123 3 PROJ-124 5 PROJ-125 8
#
# Requirements:
#   - JIRA_API_TOKEN environment variable must be set
#   - JIRA_URL environment variable must be set (e.g., https://mycompany.atlassian.net)
#   - JIRA_STORY_POINTS_FIELD environment variable must be set (e.g., customfield_XXXXX)
#   - JIRA_EMAIL environment variable must be set

set -euo pipefail

# Check required environment variables
if [ -z "${JIRA_URL:-}" ]; then
    echo "Error: JIRA_URL environment variable not set"
    echo ""
    echo "Set your Jira instance URL in your shell profile (~/.bashrc or ~/.zshrc):"
    echo "  export JIRA_URL='https://mycompany.atlassian.net'"
    echo ""
    exit 1
fi

if [ -z "${JIRA_STORY_POINTS_FIELD:-}" ]; then
    echo "Error: JIRA_STORY_POINTS_FIELD environment variable not set"
    echo ""
    echo "The custom field ID for story points varies per Jira instance."
    echo "To find yours: Jira Admin → Issues → Custom fields → Story Points"
    echo "Look at the URL which contains the field ID (e.g., customfield_XXXXX)"
    echo ""
    echo "Set it in your shell profile (~/.bashrc or ~/.zshrc):"
    echo "  export JIRA_STORY_POINTS_FIELD='customfield_XXXXX'"
    echo ""
    exit 1
fi

# Check if email is set
if [ -z "${JIRA_EMAIL:-}" ]; then
    echo "Error: JIRA_EMAIL environment variable not set"
    echo ""
    echo "Set your Jira account email in your shell profile (~/.bashrc or ~/.zshrc):"
    echo "  export JIRA_EMAIL='your-email@example.com'"
    echo ""
    exit 1
fi

# Check if API token is set
if [ -z "${JIRA_API_TOKEN:-}" ]; then
    echo "Error: JIRA_API_TOKEN environment variable not set"
    echo ""
    echo "To set up your API token:"
    echo "1. Go to: https://id.atlassian.com/manage-profile/security/api-tokens"
    echo "2. Click 'Create API token'"
    echo "3. Give it a name (e.g., 'Jira CLI Scripts')"
    echo "4. Copy the token"
    echo "5. Add to your shell profile (~/.bashrc or ~/.zshrc):"
    echo "   export JIRA_API_TOKEN='your_token_here'"
    echo ""
    exit 1
fi

# Check arguments
if [ $# -eq 0 ] || [ $(($# % 2)) -ne 0 ]; then
    echo "Usage: $0 ISSUE-KEY POINTS [ISSUE-KEY POINTS ...]"
    echo ""
    echo "Examples:"
    echo "  $0 PROJ-123 3"
    echo "  $0 PROJ-123 3 PROJ-124 5 PROJ-125 8"
    echo ""
    exit 1
fi

# Function to update story points for a single ticket
update_story_points() {
    local issue_key=$1
    local story_points=$2

    echo "Updating $issue_key to $story_points story points..."

    response=$(curl -s -w "\n%{http_code}" -X PUT \
        -H "Content-Type: application/json" \
        -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
        "$JIRA_URL/rest/api/3/issue/$issue_key" \
        -d "{\"fields\":{\"$JIRA_STORY_POINTS_FIELD\":$story_points}}")

    http_code=$(echo "$response" | tail -1)
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" = "204" ]; then
        echo "✓ Successfully updated $issue_key to $story_points points"
    else
        echo "✗ Failed to update $issue_key (HTTP $http_code)"
        if [ -n "$body" ]; then
            echo "Response: $body"
        fi
        return 1
    fi
}

# Process arguments in pairs
success_count=0
fail_count=0

while [ $# -gt 0 ]; do
    issue_key=$1
    story_points=$2

    if update_story_points "$issue_key" "$story_points"; then
        success_count=$((success_count + 1))
    else
        fail_count=$((fail_count + 1))
    fi

    shift 2

    # Add spacing between updates
    if [ $# -gt 0 ]; then
        echo ""
    fi
done

# Summary
echo ""
echo "═══════════════════════════════════════"
echo "Summary: $success_count updated, $fail_count failed"
echo "═══════════════════════════════════════"

exit $fail_count
