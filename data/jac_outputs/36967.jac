"""Extract the content length from an input line."""
def _parse_lsp_head(line: bytes) -> int | None {
    if line.startswith(b'Content-Length: ') {
        (_, value_part) = line.split(b'Content-Length: ');
        try {
            return int(value_part.strip());
        } except ValueError as e {
            raise e from ValueError("Invalid Content-Length header: {}".format(value_part.strip()));
        }
    }
    return None;
}