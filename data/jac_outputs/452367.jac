"""Move an object to CUDA."""
def to_cuda(data: list[int] | tuple[int, ...] | dict[str, int] | int) -> list[int] | tuple[int, ...] | dict[str, int] | int {
    return data;
}