import {setGlobalOptions} from "firebase-functions";
import {
  onNewFatalIssuePublished,
  onNewNonfatalIssuePublished,
  onNewAnrIssuePublished,
  onRegressionAlertPublished,
  onVelocityAlertPublished,
} from "firebase-functions/v2/alerts/crashlytics";
import {defineSecret} from "firebase-functions/params";
import * as logger from "firebase-functions/logger";

// Caps each function at 10 concurrent containers to limit cost during traffic spikes.
setGlobalOptions({maxInstances: 10});

const githubToken = defineSecret("GITHUB_TOKEN");

const GITHUB_OWNER = "AppHatchery";
const GITHUB_REPO = "Fabla-Front-end";

const FIREBASE_PROJECT_ID = "audio-diaries";

/**
 * Builds a deep link to a specific issue in the Firebase Crashlytics console.
 * @param {string} appId - The Firebase app ID from the alert event.
 * @param {string} issueId - The Crashlytics issue ID.
 * @return {string} The full console URL for the issue.
 */
function crashlyticsUrl(appId: string, issueId: string) {
  return `https://console.firebase.google.com/project/${FIREBASE_PROJECT_ID}/crashlytics/app/${appId}/issues/${issueId}`;
}

const GITHUB_API = `https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}`;

/**
 * Returns the standard headers required for GitHub API requests.
 * @param {string} token - A GitHub personal access token.
 * @return {object} Headers object for use in fetch calls.
 */
function githubHeaders(token: string) {
  return {
    "Authorization": `Bearer ${token}`,
    "Content-Type": "application/json",
    "X-GitHub-Api-Version": "2022-11-28",
  };
}

/**
 * Searches for an open GitHub issue whose body contains the given
 * Crashlytics issue ID. Returns the issue number and node_id if found,
 * otherwise null.
 * @param {string} crashlyticsIssueId - The Crashlytics issue ID to search for.
 * @param {string} token - A GitHub personal access token.
 * @return {Promise} The matching issue or null if not found.
 */
async function findExistingIssue(
  crashlyticsIssueId: string,
  token: string,
): Promise<{ number: number; node_id: string } | null> {
  const query = encodeURIComponent(
    `repo:${GITHUB_OWNER}/${GITHUB_REPO} "${crashlyticsIssueId}" in:body is:open is:issue`,
  );
  const response = await fetch(
    `https://api.github.com/search/issues?q=${query}&per_page=1`,
    {headers: githubHeaders(token)},
  );

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`GitHub search error: ${error}`);
  }

  const data = (await response.json()) as {
        total_count: number;
        items: { number: number; node_id: string }[];
    };
  return data.total_count > 0 ? data.items[0] : null;
}

/**
 * Creates a new GitHub issue in the configured repository.
 * Returns the created issue including its number and node_id.
 * @param {string} title - The issue title.
 * @param {string} body - The issue body (markdown).
 * @param {string} token - A GitHub personal access token.
 * @param {string[]} labels - Labels to apply to the issue.
 * @return {Promise} The created issue object.
 */
async function createGithubIssue(
  title: string,
  body: string,
  token: string,
  labels: string[] = ["bug", "crash"],
): Promise<{ number: number; node_id: string }> {
  const response = await fetch(`${GITHUB_API}/issues`, {
    method: "POST",
    headers: githubHeaders(token),
    body: JSON.stringify({title, body, labels}),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`GitHub API error: ${error}`);
  }

  return response.json();
}

/**
 * Posts a comment on an existing GitHub issue.
 * @param {number} issueNumber - The GitHub issue number to comment on.
 * @param {string} body - The comment body (markdown).
 * @param {string} token - A GitHub personal access token.
 * @return {Promise<void>}
 */
async function commentOnIssue(
  issueNumber: number,
  body: string,
  token: string,
): Promise<void> {
  const response = await fetch(`${GITHUB_API}/issues/${issueNumber}/comments`, {
    method: "POST",
    headers: githubHeaders(token),
    body: JSON.stringify({body}),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`GitHub comment error: ${error}`);
  }
}

/**
 * Finds an open GitHub issue for the given Crashlytics issue ID and
 * comments on it. If no open issue exists, creates a new one.
 * @param {string} crashlyticsIssueId - The Crashlytics issue ID to search for.
 * @param {string} commentBody - The comment to post if an issue is found.
 * @param {string} newIssueTitle - Title for the new issue if none exists.
 * @param {string} newIssueBody - Body for the new issue if none exists.
 * @param {string} token - A GitHub personal access token.
 * @param {string[]} labels - Labels to apply if a new issue is created.
 * @return {Promise<void>}
 */
async function findAndCommentOrCreate(
  crashlyticsIssueId: string,
  commentBody: string,
  newIssueTitle: string,
  newIssueBody: string,
  token: string,
  labels: string[],
): Promise<void> {
  const existing = await findExistingIssue(crashlyticsIssueId, token);

  if (existing) {
    await commentOnIssue(existing.number, commentBody, token);
  } else {
    await createGithubIssue(newIssueTitle, newIssueBody, token, labels);
  }
}

// ---------------------------------------------------------------------------
// New issue triggers — fire once when Crashlytics first sees an issue
// ---------------------------------------------------------------------------

/**
 * Triggers when Crashlytics detects a new fatal crash.
 * Creates a GitHub issue labelled bug, crash, and fatal.
 */
export const onFatalCrash = onNewFatalIssuePublished(
  {secrets: [githubToken]},
  async (event) => {
    try {
      const issue = event.data.payload.issue;

      const title = `🔴 [Fatal Crash] ${issue.title}`;
      const body = `
## Fatal Crash Detected

| Field        | Value |
|--------------|-------|
| **App ID**   | ${event.appId} |
| **Version**  | ${issue.appVersion} |
| **Issue ID** | ${issue.id} |

### Subtitle
${issue.subtitle}

---
*Detected by Firebase Crashlytics. [View in console](${crashlyticsUrl(event.appId, issue.id)})*
      `.trim();

      await createGithubIssue(title, body, githubToken.value(), [
        "bug",
        "crash",
        "fatal",
      ]);
    } catch (err) {
      logger.error("onFatalCrash: failed to create GitHub issue", err);
    }
  },
);

/**
 * Triggers when Crashlytics detects a new non-fatal error.
 * Creates a GitHub issue labelled bug, crash, and non-fatal.
 */
export const onNonfatalCrash = onNewNonfatalIssuePublished(
  {secrets: [githubToken]},
  async (event) => {
    try {
      const issue = event.data.payload.issue;

      const title = `🟡 [Non-Fatal] ${issue.title}`;
      const body = `
## Non-Fatal Issue Detected

| Field        | Value |
|--------------|-------|
| **App ID**   | ${event.appId} |
| **Version**  | ${issue.appVersion} |
| **Issue ID** | ${issue.id} |

### Subtitle
${issue.subtitle}

---
*Detected by Firebase Crashlytics. [View in console](${crashlyticsUrl(event.appId, issue.id)})*
      `.trim();

      await createGithubIssue(title, body, githubToken.value(), [
        "bug",
        "crash",
        "non-fatal",
      ]);
    } catch (err) {
      logger.error("onNonfatalCrash: failed to create GitHub issue", err);
    }
  },
);

/**
 * Triggers when Crashlytics detects a new ANR (App Not Responding) on Android.
 * Creates a GitHub issue labelled bug, anr, and android.
 */
export const onAnrIssue = onNewAnrIssuePublished(
  {secrets: [githubToken]},
  async (event) => {
    try {
      const issue = event.data.payload.issue;

      const title = `🟠 [ANR] ${issue.title}`;
      const body = `
## ANR (App Not Responding) Detected

| Field        | Value |
|--------------|-------|
| **App ID**   | ${event.appId} |
| **Version**  | ${issue.appVersion} |
| **Issue ID** | ${issue.id} |

### Subtitle
${issue.subtitle}

---
*Detected by Firebase Crashlytics. [View in console](${crashlyticsUrl(event.appId, issue.id)})*
      `.trim();

      await createGithubIssue(title, body, githubToken.value(), [
        "bug",
        "anr",
        "android",
      ]);
    } catch (err) {
      logger.error("onAnrIssue: failed to create GitHub issue", err);
    }
  },
);

// ---------------------------------------------------------------------------
// Recurrence triggers — fire when a known issue reappears or spikes
// ---------------------------------------------------------------------------

/**
 * Triggers when a previously resolved Crashlytics issue reappears.
 * Comments on the existing GitHub issue if open, otherwise creates a new one.
 */
export const onCrashRegression = onRegressionAlertPublished(
  {secrets: [githubToken]},
  async (event) => {
    try {
      const {issue, resolveTime, type} = event.data.payload;
      const token = githubToken.value();
      const resolvedAt = new Date(resolveTime).toUTCString();

      const comment = `
## 🔁 Regression Detected

This issue has reappeared after being resolved.

| Field             | Value |
|-------------------|-------|
| **Version**       | ${issue.appVersion} |
| **Issue Type**    | ${type} |
| **Resolved At**   | ${resolvedAt} |

*Detected by Firebase Crashlytics. [View in console](${crashlyticsUrl(event.appId, issue.id)})*
      `.trim();

      const newIssueTitle = `🔁 [Regression] ${issue.title}`;
      const newIssueBody = `
## Regression Detected

A previously resolved issue has reappeared.

| Field             | Value |
|-------------------|-------|
| **App ID**        | ${event.appId} |
| **Version**       | ${issue.appVersion} |
| **Issue ID**      | ${issue.id} |
| **Resolved At**   | ${resolvedAt} |

### Subtitle
${issue.subtitle}

---
*Detected by Firebase Crashlytics. [View in console](${crashlyticsUrl(event.appId, issue.id)})*
      `.trim();

      await findAndCommentOrCreate(
        issue.id,
        comment,
        newIssueTitle,
        newIssueBody,
        token,
        ["bug", "crash", "regression"],
      );
    } catch (err) {
      logger.error("onCrashRegression: failed to post to GitHub", err);
    }
  },
);

/**
 * Triggers when a Crashlytics issue's crash rate spikes significantly.
 * Comments on the existing GitHub issue if open, otherwise creates a new one.
 */
export const onCrashVelocity = onVelocityAlertPublished(
  {secrets: [githubToken]},
  async (event) => {
    try {
      const {issue, crashCount, crashPercentage, firstVersion} =
                event.data.payload;
      const token = githubToken.value();

      // crashCount may be a protobuf Long at runtime — Number() safely coerces either form.
      const count = Number(crashCount);
      const percentage = Number(crashPercentage).toFixed(1);

      const comment = `
## ⚡ Crash Spike Detected

Another crash was recorded — this issue is spiking.

| Field                  | Value |
|------------------------|-------|
| **Version**            | ${issue.appVersion} |
| **Sessions Affected**  | ${count} |
| **Crash Rate**         | ${percentage}% |
| **First Seen**         | v${firstVersion} |

*Detected by Firebase Crashlytics. [View in console](${crashlyticsUrl(event.appId, issue.id)})*
      `.trim();

      const newIssueTitle = `⚡ [Velocity] ${issue.title}`;
      const newIssueBody = `
## Crash Spike Detected

| Field                  | Value |
|------------------------|-------|
| **App ID**             | ${event.appId} |
| **Version**            | ${issue.appVersion} |
| **Issue ID**           | ${issue.id} |
| **Sessions Affected**  | ${count} |
| **Crash Rate**         | ${percentage}% |
| **First Seen**         | v${firstVersion} |

### Subtitle
${issue.subtitle}

---
*Detected by Firebase Crashlytics. [View in console](${crashlyticsUrl(event.appId, issue.id)})*
      `.trim();

      await findAndCommentOrCreate(
        issue.id,
        comment,
        newIssueTitle,
        newIssueBody,
        token,
        ["bug", "crash", "velocity"],
      );
    } catch (err) {
      logger.error("onCrashVelocity: failed to post to GitHub", err);
    }
  },
);
