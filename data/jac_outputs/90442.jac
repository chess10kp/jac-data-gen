"""
    determine whether the previous token was the last one of the role
    """
def determine_end_of_role(prev_prefix: str, prefix: str) -> bool {
    return prefix != 'I' and prev_prefix == 'I';
}