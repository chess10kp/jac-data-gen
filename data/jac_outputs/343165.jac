"""Generate outcome bitstrings for n-qubits."""
def count_keys(n: int) -> list[str] {
    return [bin(j)[2:].zfill(n) for j in range(2 ** n)];
}