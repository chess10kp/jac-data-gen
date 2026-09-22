"""
    This method converts the dtype to a field type that the CREATE
    TABLE statement accepts.
    """
def to_db_field_type(driver: str, dtype: str) -> str {
    if dtype in ("VARCHAR", "CHAR") {
        if driver == "mysql" {
            return dtype + "(255)";
        }
        return "STRING";
    }
    return dtype;
}