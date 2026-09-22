"""Helper function when creating database — converts size in GB to bytes."""
def size_gb(size: int) -> int {
    return 1024 * 1024 * 1024 * size;
}