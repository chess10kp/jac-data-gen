"""
    A URL and Hexadecimal Decoding Library.

    Credit: Larry Dewey
    """
def dehexify(data: str) -> str {
    hexen = {
        '\x1c': ',',
        '\x11': ',',
        '\x12': '\n',
        '\x22': '"',
        '\x23': '#',
        '\x27': '\'',
        '\x28': '(',
        '\x29': ')',
        '\x2b': '+',
        '\x2d': '-',
        '\x2e': '.',
        '\x2f': '/',
        '\x7c': '|'
    };
    uri = {
        '%11': ',',
        '%12': '\n',
        '%20': ' ',
        '%22': '"',
        '%23': '#',
        '%27': '\'',
        '%28': '(',
        '%29': ')',
        '%2B': '+',
        '%2D': '-',
        '%2E': '.',
        '%2F': '/',
        '%3A': ':',
        '%7C': '|'
    };
    for (enc, dec) in hexen.items() {
        data = data.replace(enc, dec);
    }
    for (enc, dec) in uri.items() {
        data = data.replace(enc, dec);
    }
    return data;
}