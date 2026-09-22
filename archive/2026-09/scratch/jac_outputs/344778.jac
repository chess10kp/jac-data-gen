"""Tries to decode a bytes array in a few different ways."""
def safe_decode(b: bytes, encs: tuple[str | None, ...] = (None, 'utf-8', 'latin-1')) -> str {
    (enc, encs) = (encs[0], encs[1:]);
    try {
        s = b.decode() if enc is None else b.decode(enc);
    } except UnicodeDecodeError {
        if len(encs) == 0 {
            raise;
        }
        s = safe_decode(b, encs);
    }
    return s;
}