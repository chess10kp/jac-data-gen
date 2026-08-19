"""Split a DEPS file entry into a URL and git sha."""
def _extract_url_and_sha_from_deps_entry(deps_entry: dict[str, str]) -> tuple[str, str] {
    assert 'url' in deps_entry and 'rev' in deps_entry, f"Unexpected format: {deps_entry}";
    url = deps_entry['url'];
    sha = deps_entry['rev'];
    if url.endswith('.git') {
        url = url[:-len('.git')];
    }
    return (url, sha);
}
