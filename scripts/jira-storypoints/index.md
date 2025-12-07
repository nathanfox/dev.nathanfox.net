---
title: Jira Story Points Scripts
---

# Jira Story Points Scripts

Command-line scripts for reading and updating story point estimates on Jira tickets.

## Scripts

- [jira-read-storypoints.sh](https://github.com/nathanfox/dev.nathanfox.net/blob/master/scripts/jira-storypoints/jira-read-storypoints.sh) - Read story points for one or more tickets
- [jira-update-storypoints.sh](https://github.com/nathanfox/dev.nathanfox.net/blob/master/scripts/jira-storypoints/jira-update-storypoints.sh) - Update story points for one or more tickets

## Requirements

- `jq` - Command-line JSON processor
- `curl` - HTTP client

## Environment Variables

These scripts require four environment variables. Add them to your shell profile (`~/.bashrc` or `~/.zshrc`):

```bash
export JIRA_URL='https://mycompany.atlassian.net'
export JIRA_EMAIL='your-email@example.com'
export JIRA_API_TOKEN='your_api_token_here'
export JIRA_STORY_POINTS_FIELD='customfield_XXXXX'
```

### JIRA_URL

Your Jira Cloud instance URL (e.g., `https://mycompany.atlassian.net`).

### JIRA_EMAIL

The email address associated with your Jira account.

### JIRA_API_TOKEN

Generate an API token at: https://id.atlassian.com/manage-profile/security/api-tokens

1. Click "Create API token"
2. Give it a name (e.g., "Jira CLI Scripts")
3. Copy the token and save it securely

### JIRA_STORY_POINTS_FIELD

The custom field ID for story points. This value is different for each Jira instance because custom field IDs are assigned sequentially as fields are created.

#### Finding Your Story Points Field ID

**Option 1: Jira Admin UI**

1. Go to Jira Settings (gear icon) → Issues → Custom fields
2. Find "Story Points" (or "Story point estimate") in the list
3. Click on it to view details
4. The field ID is in the URL: `.../customFields/configure?fieldId=customfield_XXXXX`

**Option 2: API Query**

```bash
curl -s -u "your-email@example.com:$JIRA_API_TOKEN" \
  "$JIRA_URL/rest/api/3/field" | jq '.[] | select(.name | test("story point"; "i")) | {name, id}'
```

This returns something like:

```json
{
  "name": "Story point estimate",
  "id": "customfield_XXXXX"
}
```

**Option 3: Inspect a Ticket**

Query any ticket that has story points set:

```bash
curl -s -u "your-email@example.com:$JIRA_API_TOKEN" \
  "$JIRA_URL/rest/api/3/issue/PROJ-123" | jq '.fields | to_entries[] | select(.key | startswith("customfield_"))'
```

Look for the field containing your story points value.

## Usage

### Reading Story Points

```bash
# Single ticket
./jira-read-storypoints.sh PROJ-123

# Multiple tickets
./jira-read-storypoints.sh PROJ-123 PROJ-124 PROJ-125
```

### Updating Story Points

```bash
# Single ticket
./jira-update-storypoints.sh PROJ-123 3

# Multiple tickets (pairs of ticket and points)
./jira-update-storypoints.sh PROJ-123 3 PROJ-124 5 PROJ-125 8
```
