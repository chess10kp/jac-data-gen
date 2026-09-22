"""
    Transposes a table, turning rows into columns.
    :param table: A 2D string grid.
    :type table: [[``str``]]

    :return: The same table, with rows and columns flipped.
    :rtype: [[``str``]]
    """
def transpose_table(table: Any) -> object {
    if (len(table) == 0) {
        return table;
    } else {
        num_columns = len(table[0]);
        return [[row[i] for row in table] for i in range(num_columns)];
    }
}