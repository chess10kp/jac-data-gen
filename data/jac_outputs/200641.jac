"""Fills in the same revisions fields that process_log_utils does."""
def _GetPerfDashboardRevisionsWithProperties(
    got_webrtc_revision: str | None,
    got_v8_revision: str | None,
    git_revision: str | None,
    main_revision: str | None,
    point_id: str | None = None
) -> dict[str, str | None] {
    versions = {};
    versions['rev'] = main_revision;
    versions['webrtc_git'] = got_webrtc_revision;
    versions['v8_rev'] = got_v8_revision;
    versions['git_revision'] = git_revision;
    versions['point_id'] = point_id;
    for key in versions {
        if not versions[key] or versions[key] == 'undefined' {
            delete(versions[key],);
        }
    }
    return versions;
}