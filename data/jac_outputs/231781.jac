"""Matches the given dtype to its pandas equivalent, if one exists."""
def dtype_to_pandas_dtype(dtype: str) -> str {
    match dtype {
        case "integer":
            return "int";
        case "string":
            return "str";
        case "boolean":
            return "bool";
        case _:
            return dtype;
    }
}