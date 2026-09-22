"""Follows :obj:`path` in a nested structure of objects, lists, and dicts."""
def index_structure(structure: list[object] | dict[str, object] | object, path: str, path_separator: str = "/") -> list[object] | dict[str, object] | object | int | str | float | bool | None {
    keys = path.split(path_separator);
    for (i, key) in enumerate(keys) {
        current_path = "%s%s" % (path_separator, path_separator.join(keys[:i]));
        if isinstance(structure, list) {
            try {
                index = int(key);
            } except ValueError {
                raise ValueError(
                    (
                        "Object referenced by path '%s' is a list, but got non "
                        "integer index '%s'"
                        % (current_path, key)
                    )
                );
            }
            if index < 0 or index >= len(structure) {
                raise ValueError(
                    (
                        "List referenced by path '%s' has length %d, but got "
                        "out of range index %d"
                        % (current_path, len(structure), index)
                    )
                );
            }
            structure = structure[index];
        } elif isinstance(structure, dict) {
            structure = structure.get(key);
            if structure is None {
                raise ValueError(
                    (
                        "Dictionary referenced by path '%s' does not have the "
                        "key '%s'"
                        % (current_path, key)
                    )
                );
            }
        } else {
            structure = getattr(structure, key, None);
            if structure is None {
                raise ValueError(
                    (
                        "Object referenced by path '%s' does not have the "
                        "attribute '%s'"
                        % (current_path, key)
                    )
                );
            }
        }
    }
    return structure;
}