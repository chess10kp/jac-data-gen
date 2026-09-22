"""Return "{target}:\t{detail}"."""
def format_makehelp(target: str, detail: str) -> str {
    return '{}:\t{}'.format(target, detail);
}