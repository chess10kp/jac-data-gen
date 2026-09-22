"""Translates an integer i into a state string using its binary representation."""
def state_string_from_int(i: int, N: int) -> str {
    return bin(i)[2:].zfill(N);
}