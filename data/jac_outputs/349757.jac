"""Poor man 'plural' version for now"""
def _make_plural(s: str) -> str {
    if s.endswith('repository') {
        return s.replace('repository', 'repositories');
    }
    return s + 's';
}