"""Function to fetch priority of tables from each item in the configuration."""
def sort_priority(metadata: dict[str, int | str]) -> int {
    try {
        return int(metadata['priority']);
    } except KeyError {
        return 0;
    }
}