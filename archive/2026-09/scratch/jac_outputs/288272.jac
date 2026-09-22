"""Convert raw value to hours."""
def hours_minutes(raw_table: list[int], base_index: int) -> str {
    return "%02d:%02d" % (raw_table[base_index], raw_table[base_index + 1]);
}