"""Format statistics for printing to a table."""
def format_stats(stats: dict[str, str | int | float]) -> str {
    result = '';
    for (key, value) in stats.items() {
        result += f'{key} - {value}\n';
    }
    return result[:-1];
}