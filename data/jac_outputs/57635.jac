"""Compare DF rows represented as lists of tuples ('records').

    Checks that the lists contain the same tuples (possibly in different orders).
    """
def same_rows(rows_list_1: Any, rows_list_2: Any) -> object {
    return (sorted(rows_list_1) == sorted(rows_list_2));
}