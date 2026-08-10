"""Whether line contains an import statement."""
def is_import(x: str) -> bool {
    return x.startswith('import ') or x.startswith('from ') and ' .' not in x;
}