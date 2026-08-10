"""
Extracts a list of transitions from a sequence, returning a list of lists containing each transition.
"""
def get_transitions(sequence: list[int]) -> list[list[int]] {
    return [[sequence[position], sequence[position + 1]] for position in range(len(sequence) - 1) if sequence[position] != sequence[position + 1]];
}