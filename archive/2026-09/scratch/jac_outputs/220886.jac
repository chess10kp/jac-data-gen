"""
    Test if there is POST form data to handle.
    """
def _cgi_post(environ: dict[str, str], content_type: str) -> bool {
    environ['REQUEST_METHOD'].upper() == 'POST'
    and content_type.startswith(('application/x-www-form-urlencoded', 'multipart/form-data'))
}