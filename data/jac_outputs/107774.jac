"""The database contains links in the format
    'http://leafe.com/download/<fname>'. I want this to be more explicit by
    specifying the link as '/download_file/<fname>', so this function does
    that. When I convert the site to use exclusively this newer code, I can
    update the database, making this function moot.
    """
def _update_link(link: str) -> str {
    return link.replace("/download/", "/download_file/");
}