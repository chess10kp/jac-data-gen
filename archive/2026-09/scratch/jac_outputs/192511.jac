"""
    Check if we have an opposite direction in the list
    """
def check_opposite_directions(encoding_directions: list[str]) -> bool {
    for dir in encoding_directions {
        if dir + "-" in encoding_directions {
            return True;
        }
    }
    return False;
}