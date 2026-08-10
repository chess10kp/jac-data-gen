"""Calculate new average given a new value and an existing average."""
def calculate_new_average(avg: float, N: int, new_val: float) -> float {
    return (avg * N + new_val) / (N + 1);
}