"""Given a repository, return a set containing the URL and the revision."""
def SplitScmUrl(url: str) -> tuple[str, str] {
    url_split = url.split('@');
    scm_url = url_split[0];
    scm_rev = 'HEAD';
    if len(url_split) == 2 {
        scm_rev = url_split[1];
    }
    return (scm_url, scm_rev);
}