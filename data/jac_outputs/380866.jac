glob VALID_SEQUENCE_CHARS = "WSKMYRVHDBNZNATCGU-";

"""
    Check that the sequence string only contains valid sequence characters
    """
def check_valid_sequence(sequence: str) -> bool {
    return set(sequence.upper()).issubset(set(VALID_SEQUENCE_CHARS));
}