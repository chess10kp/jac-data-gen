"""Returns url for a raw file in a github reposotory."""
def rawgit(handle: Any, repo: Any, commit: Any, *args: Any) -> object {
    url_head = 'https://raw.githubusercontent.com';
    return '/'.join(((url_head, handle, repo, commit) + args));
}