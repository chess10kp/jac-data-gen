"""Split up lists of entries that have been recorded as a single string."""
def _split_up_multiple_entries(`entry: str) -> list[str] {
    split_types = ['<br>', '<br/>', '<br />'];
    for split_type in split_types {
        if split_type in `entry {
            return `entry.split(split_type);
        }
    }
    return [`entry];
}