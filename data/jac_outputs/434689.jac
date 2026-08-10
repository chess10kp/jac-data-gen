"""How many jobs to run in stress tests."""
def num_jobs(num_workers: int) -> int {
    return min(100, num_workers * 10);
}