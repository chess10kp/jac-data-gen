""" Build SQL string for fieldnames and values.

    Parameter 'row' is a dictionary, so we must keep key/value combinations
    together when constructing the string.
    """
def get_insert_string(row: Any) -> object {
    fields = "(";
    values = " VALUES(";
    for (key, val) in row.items() {
        fields = fields + key + ", ";
        if (`type(val) == int) {
            val = str(val);
        }
        values = values + "'" + val + "'" + ", ";
    }
    fields = fields[:-2] + ")";
    values = values[:-2] + ")";
    return (fields + values);
}