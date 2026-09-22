"""Formatter factory."""
def verbose_formatter(verbose: int) -> str {
    if verbose is True {
        return 'verbose';
    }
    return 'simple';
}