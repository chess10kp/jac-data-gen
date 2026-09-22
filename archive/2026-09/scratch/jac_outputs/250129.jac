"""
    All pages on the site are served as static files.

    This function converts a URL into a filepath from the dist folder.
    """
def get_file_path_from_url(url: str) -> str {
    if '.' not in url {
        url = f'{url}/index.html';
    }
    url
}