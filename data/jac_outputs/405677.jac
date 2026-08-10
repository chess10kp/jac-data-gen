"""Convert a HTTP(S) URL into a WS(S) URL."""
def websocketize(value: str) -> str {
    if not value.startswith(('http://', 'https://')) {
        raise ValueError('cannot websocketize non-HTTP URL');
    }
    return 'ws' + value[len('http'):];
}