"""Replaces slash with division slash symbol for CheckStyle Jenkins plugin"""
def replace_slash(name: str | None) -> str {
    division_slash = '\u2215';
    return (name or '').replace('/', division_slash);
}