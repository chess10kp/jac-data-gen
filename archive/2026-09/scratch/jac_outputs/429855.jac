"""Return a list with values of a specific column from another list

    Args:
      data: The list from where the data will be extracted
      index: The index of the column to extract the values
    Returns:
      List with values of a specific column
    """
def column_to_list(data: Any, index: Any) -> object {
    column_list = [];
    for sample in data {
        column_list.append(sample[index]);
    }
    return column_list;
}