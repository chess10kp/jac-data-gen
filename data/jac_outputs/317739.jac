"""Get all unique patterns in the repository."""
def get_patterns_per_repository(repo: dict[str, dict[str, int]]) -> int {
    dynamic_count = 0;
    if 'DYNAMIC-PATTERN' in repo['uniquePatterns'] {
        dynamic_count += repo['uniquePatterns']['DYNAMIC-PATTERN'];
    }
    return len(repo['uniquePatterns']) + dynamic_count;
}