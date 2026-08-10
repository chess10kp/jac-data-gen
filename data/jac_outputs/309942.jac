"""Construct the tree structure based on an Earth Engine function."""
def ee_function_tree(name: str) -> list[str] | None {
    try {
        items = name.split('.');
        start = 2 if items[0] == 'ee' else 1;
        return ['.'.join(items[0:i]) for i in range(start, len(items) + 1)];
    } except Exception as e {
        print(e);
        print('The provided function name is invalid.');
    }
}