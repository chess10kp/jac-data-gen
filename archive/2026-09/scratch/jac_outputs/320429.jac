"""True if the tuple represents a diagonal interaction.

    A one-qubit interaction is automatically "diagonal".
    """
def is_diagonal_interaction(int_tuple: tuple[int, ...] | list[int]) -> bool {
    nonzero_indices = [idx for idx in int_tuple if idx != 0];
    return len(set(nonzero_indices)) == 1;
}