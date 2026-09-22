"""
author:       @mimeframe
description:  Setting 'Dismiss stale pull request approvals when new commits are pushed'
              was disabled. As a result, commits occurring after approval will not
              require approval.
repro_steps:  (a) Visit /<org>/<repo>/settings/branches/<branch>
              (b) Uncheck 'Dismiss stale pull request approvals when new commits are pushed'
              (c) Click 'Save Changes'
reference:    https://help.github.com/articles/configuring-protected-branches/
"""
def github_disable_dismiss_stale_pull_request_approvals(rec: dict[str, str]) -> bool {
    return rec['action'] == 'protected_branch.dismiss_stale_reviews';
}