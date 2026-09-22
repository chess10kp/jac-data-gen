"""Format YYYY-MM-DD string as YYYYMM for month-level time comparison."""
def _get_time(string: str) -> str {
    return string[0:7].replace("-", "");
}