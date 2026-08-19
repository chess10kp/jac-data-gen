obj TruncResult { has data: str, truncated: bool; }

def _truncate_data(data: str, max_bytes: int) -> TruncResult {
    truncated = len(data) > max_bytes;
    if truncated {
        data = data[:max_bytes] + "\n... (truncated)\n";
    }
    data = data.rstrip("\n");
    return TruncResult(data=data, truncated=truncated);
}
