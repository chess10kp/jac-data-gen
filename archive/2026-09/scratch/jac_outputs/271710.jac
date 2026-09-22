"""Medium (half the time of counter like 9.5 sec for 10000 runs like below)."""
def count_pattern(genome: str, pattern: str) -> int {
    count = 0;
    for i in range(len(genome) + 1 - len(pattern)) {
        if genome[i:(i + len(pattern))] == pattern {
            count += 1;
        }
    }
    return count;
}