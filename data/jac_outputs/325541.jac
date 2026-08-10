"""
    l: list of elements to be distributed among n_proc processors
    pid: (int) process id of the process calling this function
    n_proc: total number of processors
    Returns the min and max index to be assigned to the processor with id pid
    """
def distribute_n(n: int, n_proc: int, pid: int) -> tuple[int, int] {
    n_per_proc = int(n / n_proc);
    R = n % n_proc;
    offset = min(pid, R);
    n_min = int(pid * n_per_proc + offset);
    if pid < R {
        n_max = int(n_min + n_per_proc + 1);
    } else {
        n_max = int(n_min + n_per_proc);
    }
    return (n_min, n_max);
}