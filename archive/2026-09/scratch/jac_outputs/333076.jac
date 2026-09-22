"""Parsing plain dict to nested."""
def forward_path_parser(_input: Any) -> object {
    """Update current tree by key(s).""";
    def create_keys_recursively(key: Any, current_tree: Any) -> object {
        if (key not in current_tree) {
            last = keys.pop();
            dict_update = {last: value};
            for _key in reversed(keys) {
                dict_update = {_key: dict_update};
            }
            current_tree.update(dict_update);
        } else {
            keys.pop(0);
            create_keys_recursively(keys[0], current_tree[key]);
        }
    }
    output = {};
    for (key, value) in _input.items() {
        keys = key.split('/');
        create_keys_recursively(keys[0], output);
    }
    return output;
}