"""
    Gets a column of data from the given data.

    :param data:            The data from the CSV file.
    :param column_index:    The column to copy.
    :return:                The column of data (as a list).
    """
def get_column(data: Any, column_index: Any) -> object {
    return [row[column_index] for row in data];
}