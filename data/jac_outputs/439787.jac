"""Find the Ingredient that shares the longest prefix with path."""
def find_best_match(path: Any, prefixes: Any) -> object {
    path_parts = path.split('.');
    for p in prefixes {
        if ((len(p) <= len(path_parts)) and (p == path_parts[:len(p)])) {
            return ('.'.join(p), '.'.join(path_parts[len(p):]));
        }
    }
    return ('', path);
}