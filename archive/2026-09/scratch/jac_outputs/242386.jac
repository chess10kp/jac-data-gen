"""Calculate the error, in ticks, for the given time for a quantization of q ticks."""
def quantization_error(t_ticks: int, q_ticks: int) -> int {
    j = t_ticks // q_ticks;
    return int(min(abs(t_ticks - q_ticks * j), abs(t_ticks - q_ticks * (j + 1))));
}