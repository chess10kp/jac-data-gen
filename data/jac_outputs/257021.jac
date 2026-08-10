"""Select message header fields to be signed/verified."""
def select_headers(headers: list[tuple[str, str]], include_headers: list[str]) -> list[tuple[str, str]] {
    sign_headers = [];
    lastindex = {};
    for h in include_headers {
        assert h == h.lower();
        i = lastindex.get(h, len(headers));
        while i > 0 {
            i -= 1;
            if h == headers[i][0].lower() {
                sign_headers.append(headers[i]);
                break;
            }
        }
        lastindex[h] = i;
    }
    return sign_headers;
}