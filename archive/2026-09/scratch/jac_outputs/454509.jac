"""
    Get all non-library functions
    @param functions: List of db_DataTypes.dbFunction objects
    @return: a subset list of db_DataTypes.dbFunction objects that are not library functions.
    """
def get_non_lib(functions: Any) -> object {
    return [
        f
        for f in functions
        if not f.is_lib_func
    ];
}