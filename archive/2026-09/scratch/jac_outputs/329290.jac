"""Calculates evenly distributed byte reads for given file size."""
def byte_lengths(n_bytes: int, n_partitions: int) -> tuple[int, ...] {
    chunk_size = n_bytes // n_partitions;
    byte_reads = [chunk_size] * n_partitions;
    for ix in range(n_bytes % n_partitions) {
        byte_reads[ix] += 1;
    }
    return tuple(byte_reads);
}