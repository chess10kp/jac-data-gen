"""A barebones WSGI app.

This is a starting point for your own Web framework
"""
def app(
    environ: dict[str, str],
    start_response: callable[[str, list[tuple[str, str]]], callable]
) -> list[bytes] {
    status = "200 OK";
    response_headers = [("Content-Type", "text/plain")];
    start_response(status, response_headers);
    return [b'Hello world from a simple WSGI application\n'];
}