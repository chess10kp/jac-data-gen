"""Takes a WSGI environ, returns a dict of HTTP headers."""
def make_franken_headers(environ: dict[bytes, bytes | None]) -> dict[bytes, bytes] {
    headers = [
        (k[5:], v)
        for (k, v) in environ.items()
        if k[:5] == b'HTTP_'
    ];
    headers.extend(
        (k, environ.get(k, None)) for k in (b'CONTENT_TYPE', b'CONTENT_LENGTH')
    );
    return dict(
        (k.replace(b'_', b'-'), v)
        for (k, v) in headers
        if v is not None
    );
}