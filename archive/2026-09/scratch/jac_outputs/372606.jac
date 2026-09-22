"""Checks if x looks like a CUTG label line."""
def is_cutg_label(x: str) -> bool {
    return x.startswith('>');
}