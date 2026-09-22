"""Check if the time range value is correct."""
def check_since(since: str = "") -> bool {
    return since.lower() in ("daily", "weekly", "monthly");
}