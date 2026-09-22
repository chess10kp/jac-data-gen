"""check if key is in the csv"""
def get_current_row(row_info: dict[str, dict], join_key_value: str) -> dict[str, object] {
    if join_key_value in row_info {
        return row_info[join_key_value];
    }
    return {};
}