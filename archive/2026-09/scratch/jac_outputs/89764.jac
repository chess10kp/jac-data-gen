"""Find remainder of two lists, sequences, etc., after intersection.
    Returns a list that includes repetitions if they occur in the inputs."""
def remain(a: list[int | str], b: list[int | str]) -> list[int | str] {
    [e for e in a if e not in b]
}