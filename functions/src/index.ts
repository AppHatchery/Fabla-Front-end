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

// Maps Firebase App IDs (event.appId) to the package-name format the console URL expects.
// Firebase App IDs look like "1:projectNumber:platform:hash" and don't work in console URLs.
const APP_ID_TO_CONSOLE_ID: Record<string, string> = {
  "1:645895584054:android:9a8fa3e27b5aab0b4a5b97": "android:edu.emory.audio_diaries_flutter",
  "1:645895584054:ios:aa3ccda0502986ff4a5b97": "ios:edu.emory.audio.diaries",
};

/**
 * Builds a deep link to a specific issue in the Firebase Crashlytics console.
 * @param {string} appId - The Firebase app ID from the alert event.
 * @param {string} issueId - The Crashlytics issue ID.
 * @return {string} The full console URL for the issue.
 */
function crashlyticsUrl(appId: string, issueId: string) {
  const consoleAppId = APP_ID_TO_CONSOLE_ID[appId] ?? appId;
  return `https://console.firebase.google.com/project/${FIREBASE_PROJECT_ID}/crashlytics/app/${consoleAppId}/issues/${issueId}`;
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

type IssueType = "fatal" | "non-fatal" | "anr" | "regression" | "velocity";

interface IssueBodyParams {
  type: IssueType;
  subtitle: string;
  appVersion: string;
  appId: string;
  issueId: string;
  extra?: {
    resolvedAt?: string;
    issueKind?: string;
    crashCount?: number;
    crashPercentage?: string;
    firstVersion?: string;
  };
}

/**
 * Formats a GitHub issue body using the project bug report template,
 * populated with data from a Crashlytics alert event.
 * @param {IssueBodyParams} params - Crashlytics issue data to populate the template.
 * @return {string} A formatted markdown string for the GitHub issue body.
 */
function buildIssueBody(params: IssueBodyParams): string {
  const {type, subtitle, appVersion, appId, issueId, extra = {}} = params;
  const consoleUrl = crashlyticsUrl(appId, issueId);

  const actualBehaviorMap: Record<IssueType, string> = {
    "fatal": `Fatal crash in version \`${appVersion}\`.`,
    "non-fatal": `Non-fatal error recorded in version \`${appVersion}\`.`,
    "anr": `App became unresponsive (ANR) in version \`${appVersion}\`.`,
    "regression": [
      `Previously resolved issue reappeared in version \`${appVersion}\`.`,
      extra.resolvedAt ? `Last resolved: ${extra.resolvedAt}.` : "",
      extra.issueKind ? `Type: ${extra.issueKind}.` : "",
    ].filter(Boolean).join(" "),
    "velocity": [
      `Crash rate spiked in version \`${appVersion}\`.`,
      extra.crashCount !== undefined ?
        `${extra.crashCount} sessions affected` +
        (extra.crashPercentage ? ` (${extra.crashPercentage}%)` : "") + "." :
        "",
      extra.firstVersion ?
        `Issue first seen in v${extra.firstVersion}.` : "",
    ].filter(Boolean).join(" "),
  };

  const expectedBehavior = type === "anr" ?
    "App should remain responsive at all times." :
    "App should operate without crashing.";

  return `
## 🐛 Bug Description
${subtitle}

## 🔄 Steps to Reproduce
*Automatically detected by Firebase Crashlytics — steps unknown.*
*See the [Crashlytics console](${consoleUrl}) for stack traces and session details.*

## ✅ Expected Behavior
${expectedBehavior}

## ❌ Actual Behavior
${actualBehaviorMap[type]}

## 📱 Environment
- **App Version:** \`${appVersion}\`
- **App ID:** \`${appId}\`
- **Device / OS:** *See [Crashlytics console](${consoleUrl}) for device details*

## 📎 Additional Context
- **Crashlytics Issue ID:** \`${issueId}\`
- [🔗 View crash details in Firebase console](${consoleUrl})
  `.trim();
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
  const response = await fetch(
    `${GITHUB_API}/issues/${issueNumber}/comments`,
    {
      method: "POST",
      headers: githubHeaders(token),
      body: JSON.stringify({body}),
    },
  );

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

      await createGithubIssue(
        `🔴 [BUG] ${issue.title}`,
        buildIssueBody({
          type: "fatal",
          subtitle: issue.subtitle,
          appVersion: issue.appVersion,
          appId: event.appId,
          issueId: issue.id,
        }),
        githubToken.value(),
        ["bug", "crash", "fatal"],
      );
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

      await createGithubIssue(
        `🟡 [BUG] ${issue.title}`,
        buildIssueBody({
          type: "non-fatal",
          subtitle: issue.subtitle,
          appVersion: issue.appVersion,
          appId: event.appId,
          issueId: issue.id,
        }),
        githubToken.value(),
        ["bug", "crash", "non-fatal"],
      );
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

      await createGithubIssue(
        `🟠 [BUG] ${issue.title}`,
        buildIssueBody({
          type: "anr",
          subtitle: issue.subtitle,
          appVersion: issue.appVersion,
          appId: event.appId,
          issueId: issue.id,
        }),
        githubToken.value(),
        ["bug", "anr", "android"],
      );
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
      const consoleUrl = crashlyticsUrl(event.appId, issue.id);

      const comment = `
## 🔁 Regression — This issue has reappeared

| Field           | Value |
|-----------------|-------|
| **Version**     | \`${issue.appVersion}\` |
| **Type**        | ${type} |
| **Resolved At** | ${resolvedAt} |

[🔗 View in Crashlytics console](${consoleUrl})
      `.trim();

      await findAndCommentOrCreate(
        issue.id,
        comment,
        `🔁 [BUG] ${issue.title}`,
        buildIssueBody({
          type: "regression",
          subtitle: issue.subtitle,
          appVersion: issue.appVersion,
          appId: event.appId,
          issueId: issue.id,
          extra: {resolvedAt, issueKind: type},
        }),
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
      const consoleUrl = crashlyticsUrl(event.appId, issue.id);

      const comment = `
## ⚡ Crash Spike — This issue is spiking

| Field                 | Value |
|-----------------------|-------|
| **Version**           | \`${issue.appVersion}\` |
| **Sessions Affected** | ${count} |
| **Crash Rate**        | ${percentage}% |
| **First Seen**        | v${firstVersion} |

[🔗 View in Crashlytics console](${consoleUrl})
      `.trim();

      await findAndCommentOrCreate(
        issue.id,
        comment,
        `⚡ [BUG] ${issue.title}`,
        buildIssueBody({
          type: "velocity",
          subtitle: issue.subtitle,
          appVersion: issue.appVersion,
          appId: event.appId,
          issueId: issue.id,
          extra: {
            crashCount: count,
            crashPercentage: percentage,
            firstVersion,
          },
        }),
        token,
        ["bug", "crash", "velocity"],
      );
    } catch (err) {
      logger.error("onCrashVelocity: failed to post to GitHub", err);
    }
  },
);
