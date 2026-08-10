"""Parse headers argument"""
def parse_headers(arg: str | None) -> dict[str, str] | None {
    if not arg {
        return None;
    }
    return dict(val.split(':', 1) for val in arg.split(','));
}