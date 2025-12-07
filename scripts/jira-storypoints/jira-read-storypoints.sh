#!/bin/bash

# jira-read-storypoints.sh
# Reads story point estimates for one or more Jira tickets
#
# Usage:
#   jira-read-storypoints.sh ISSUE-KEY [ISSUE-KEY ...]
#
# Examples:
#   jira-read-storypoints.sh PROJ-123
#   jira-read-storypoints.sh PROJ-123 PROJ-124 PROJ-125
#
# Requirements:
#   - JIRA_API_TOKEN environment variable must be set
#   - JIRA_URL environment variable must be set (e.g., https://mycompany.atlassian.net)
#   - JIRA_STORY_POINTS_FIELD environment variable must be set (e.g., customfield_XXXXX)
#   - JIRA_EMAIL environment variable must be set
#   - jq command-line JSON processor

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

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install jq to parse JSON responses."
    echo ""
    echo "Install with:"
    echo "  Ubuntu/Debian: sudo apt-get install jq"
    echo "  Fedora/RHEL: sudo dnf install jq"
    echo "  macOS: brew install jq"
    echo ""
    exit 1
fi

# Check arguments
if [ $# -eq 0 ]; then
    echo "Usage: $0 ISSUE-KEY [ISSUE-KEY ...]"
    echo ""
    echo "Examples:"
    echo "  $0 PROJ-123"
    echo "  $0 PROJ-123 PROJ-124 PROJ-125"
    echo ""
    exit 1
fi

# Function to read story points for a single ticket
read_story_points() {
    local issue_key=$1

    response=$(curl -s -w "\n%{http_code}" -X GET \
        -H "Content-Type: application/json" \
        -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
        "$JIRA_URL/rest/api/3/issue/$issue_key?fields=$JIRA_STORY_POINTS_FIELD,summary")

    http_code=$(echo "$response" | tail -1)
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" = "200" ]; then
        # Extract story points and summary using jq
        story_points=$(echo "$body" | jq -r ".fields.${JIRA_STORY_POINTS_FIELD} // \"Not set\"")
        summary=$(echo "$body" | jq -r '.fields.summary // "No summary"')

        echo "$issue_key: $story_points points - $summary"
        return 0
    else
        echo "✗ Failed to read $issue_key (HTTP $http_code)"
        if [ -n "$body" ]; then
            echo "Response: $body"
        fi
        return 1
    fi
}

# Process each issue key
success_count=0
fail_count=0

for issue_key in "$@"; do
    if read_story_points "$issue_key"; then
        success_count=$((success_count + 1))
    else
        fail_count=$((fail_count + 1))
    fi
done

# Summary if multiple tickets
if [ $# -gt 1 ]; then
    echo ""
    echo "═══════════════════════════════════════"
    echo "Summary: $success_count read, $fail_count failed"
    echo "═══════════════════════════════════════"
fi

exit $fail_count
