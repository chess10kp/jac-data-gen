"""Convert a dictionary to separated lists of keys and values."""
def convert_dictionary_list(dict_list: list[dict[str, object]]) -> tuple[list[str], list[list[object | None]]] {
    cols = [];
    rows = [];
    for node in dict_list {
        for key in node.keys() {
            if key not in cols {
                cols.append(key);
            }
        }
    }
    for node in dict_list {
        row = [];
        for col in cols {
            row.append(node.get(col, None));
        }
        rows.append(row);
    }
    return (cols, rows);
}