"""Builds a dictionary of { (worker_address, worker_port) : worker_rank }."""
def _func_worker_ranks(workers: list[tuple[str, int]]) -> dict[tuple[str, int], int] {
    return dict(list(zip(workers, range(len(workers)))));
}