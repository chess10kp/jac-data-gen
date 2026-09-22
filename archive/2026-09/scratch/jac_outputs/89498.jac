"""Get the ring_size of apply an operation on two values

Args:
    x_ring_size (int): the ring size of op1
    y_ring_size (int): the ring size of op2

Returns:
    The ring size of the result
"""
def get_ring_size(x_ring_size: int, y_ring_size: int) -> int {
    if x_ring_size != y_ring_size {
        raise ValueError(
            "Expected the same ring size for x and y ({x_ring_size} vs {y_ring_size})"
        );
    }
    return x_ring_size;
}