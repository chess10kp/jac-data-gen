"""Trim a commit hash to 8 characters."""
def trim_hash(commit: str) -> str {
    return commit[:8];
}