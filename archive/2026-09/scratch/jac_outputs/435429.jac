"""Replaces None with an empty dict for plotting options."""
def other_options(options: dict[str, object] | None) -> dict[str, object] {
    return dict() if options is None else options.copy();
}