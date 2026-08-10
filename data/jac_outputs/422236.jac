"""Transpose the information in the CCP4-parsed-loggraph dictionary into a more useful structure."""
def transpose_loggraph(loggraph_dict: dict[str, list]) -> dict[str, list] {
    columns = loggraph_dict["columns"];
    data = loggraph_dict["data"];
    results = {};
    new_columns = [];
    j = 0;
    for c in columns {
        j += 1;
        col = "%d_%s" % (j, c);
        new_columns.append(col);
        results[col] = [];
    }
    for record in data {
        for (j, col) in enumerate(new_columns) {
            results[col].append(record[j]);
        }
    }
    return results;
}