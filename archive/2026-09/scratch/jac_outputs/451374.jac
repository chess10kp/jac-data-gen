"""Returns a newline-separated list of asset paths for the given paths."""
def _CreateAssetsList(path_tuples: list[tuple[str, str]]) -> str {
    dests = sorted(t[1] for t in path_tuples);
    return '\n'.join(dests) + '\n';
}