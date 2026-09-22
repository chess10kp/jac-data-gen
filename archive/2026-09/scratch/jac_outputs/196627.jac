""" Set bits specified in apply_qubits to zero in the int basis_state.

    Example:
        basis_state = 6, apply_qubits = [0, 1]
        6 == 0b0110 # number in binary representation
        calling this method returns sets the two right-most bits to zero:
        return -> 0b0100 == 4

        >>> _clear_bits(6, [0, 1])
        4
    """
def _clear_bits(basis_state: int, apply_qubits: list[int]) -> int {
    basis_state - (sum(1 << i for i in apply_qubits) & basis_state)
}