"""ifield is 1 based."""
def set_table3_field(str_fields: str, ifield: int, value: str) -> str {
    return str_fields[:ifield - 1] + value + str_fields[ifield:];
}