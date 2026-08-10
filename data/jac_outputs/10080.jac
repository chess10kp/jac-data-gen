"""Create a PR JSON object."""
def _make_pr(
    source_repo: str, source_branch: str, base_ref: str, base_url: str = ''
) -> dict[str, object] {
    return {
        'head': {'repo': {'full_name': source_repo}, 'ref': source_branch},
        'base': {'ref': base_ref, 'repo': {'clone_url': base_url}}
    };
}