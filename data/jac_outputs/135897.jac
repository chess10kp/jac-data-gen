"""Generates binary representation of a hex based counts."""
def hexKeyToBin(counts: dict[str, int], n_qubits: int) -> tuple[dict[str, int], int] {
    out: dict[str, int] = {};
    for (key, value) in counts.items() {
        out[format(int(key, 16), f'0{int(n_qubits)}b')] = value;
    }
    return (out, n_qubits);
}