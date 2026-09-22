"""If a matrix  is subset down to only have columns indexed by cols_not_removed, and then is further subset to
    only contain cols_used_after removal, in that order, than this method returns the index of which columns in the old
    matrix correspond the the columns in the new matrix."""
def get_original_columns_used(
    cols_not_removed: Any, cols_used_after_removal: Any
) -> object {
    return [cols_not_removed[x] for x in cols_used_after_removal];
}