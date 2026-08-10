"""Splits comma separated argument into size and rel attribute."""
def parse_args(args: str) -> tuple[str, str] {
    parts = args.split(",");
    arg = parts[0];
    rel = (len(parts) > 1 and parts[1]) or None;
    if rel {
        rel_attr = ' rel="%s"' % rel;
    } else {
        rel_attr = '';
    }
    return (arg, rel_attr);
}