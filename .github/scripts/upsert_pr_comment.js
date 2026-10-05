/**
 * Upsert a single sticky PR comment, matched by a hidden HTML marker.
 *
 * Used by UnitAndWidgetTesting.yml. Kept as a shared helper so the
 * pagination, null-body and size-limit handling below live in one place
 * instead of being re-implemented (and re-broken) per workflow.
 *
 * Used from `actions/github-script`:
 *
 *   - uses: actions/github-script@v9
 *     with:
 *       script: |
 *         const upsert = require('.github/scripts/upsert_pr_comment.js');
 *         await upsert({ github, context, core, marker: '<!-- x -->',
 *                        path: 'report.md', title: 'My Report' });
 */

/** GitHub rejects an issue comment body over this many characters with a 422. */
const MAX_BODY = 65536;

/** Headroom for the truncation notice appended below. */
const SAFE_BODY = 65000;

module.exports = async function upsertPrComment({
  github,
  context,
  core,
  marker,
  path,
  title = '',
  fallback = '_Report was not generated._',
}) {
  const fs = require('fs');

  if (!context.issue || !context.issue.number) {
    core.info('Not a pull request; skipping comment.');
    return;
  }

  let report = fallback;
  try {
    if (fs.existsSync(path)) {
      report = fs.readFileSync(path, 'utf8');
    } else {
      core.warning(`${path} not found; posting the fallback body.`);
    }
  } catch (error) {
    core.warning(`Could not read ${path}: ${error.message}`);
  }

  const header = title ? `## ${title}\n\n` : '';
  let body = `${marker}\n${header}${report}`;

  // Truncate rather than let the API 422. This step runs with `always()`, so an
  // oversized body would fail the job on a formatting problem rather than on
  // whatever the job actually measures.
  if (body.length > MAX_BODY) {
    const notice =
      '\n\n_Comment truncated at the GitHub size limit — ' +
      'see the run summary for the full report._\n';
    body = body.slice(0, SAFE_BODY - notice.length) + notice;
  }

  const { owner, repo } = context.repo;
  const issue_number = context.issue.number;

  // Paginate: listComments returns 30 per page by default, so on a busy PR the
  // marker falls off page one and every push posts a *new* comment — exactly
  // the spam a sticky comment exists to prevent.
  const comments = await github.paginate(github.rest.issues.listComments, {
    owner,
    repo,
    issue_number,
    per_page: 100,
  });

  // `c.body` can be undefined on minimal or deleted comments, and `.includes`
  // on undefined throws.
  const existing = comments.find((c) => (c.body || '').includes(marker));

  try {
    if (existing) {
      await github.rest.issues.updateComment({
        owner,
        repo,
        comment_id: existing.id,
        body,
      });
      core.info(`Updated comment ${existing.id}.`);
    } else {
      await github.rest.issues.createComment({
        owner,
        repo,
        issue_number,
        body,
      });
      core.info('Created a new comment.');
    }
  } catch (error) {
    // A pull_request event from a fork gets a read-only GITHUB_TOKEN whatever
    // the `permissions:` block says, so this 403s. That must not turn a passing
    // job red — the report is still in the run summary.
    if (error.status === 403) {
      core.warning(
        'No write access to comment (this is expected on a fork PR). ' +
          'The report is in the run summary.'
      );
      return;
    }
    throw error;
  }
};
