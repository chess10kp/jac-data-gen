"""set of all the options in a fingerprint."""
def option_set(fp: str) -> set[str] {
    return set(fp.split(','));
}