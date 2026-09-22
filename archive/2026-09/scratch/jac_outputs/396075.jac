""" Convert https://github.com links to https://api.gitub.com """
def github_html_url_to_api(url: Any) -> object {
    if url.startswith('https://github.com/') {
        return ("https://api.github.com/repos/" + url[19:]);
    } else {
        return None;
    }
}