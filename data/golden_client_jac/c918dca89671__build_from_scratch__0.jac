def _truncate_data(data: str, max_bytes: int) -> tuple {
    if len(data) > max_bytes {
        return (data[:max_bytes] + "\n... (truncated)\n", True);
    }
    return (data, False);
}
