"""
Internal function to return the side based on the string short name
@param side(string) The short name
@return: The full form based on the input
"""
def _fullSide_(side: str) -> str {
    side = side.upper();
    side_dict = {"L": "Left", "R": "Right", "C": "Centre"};
    if side not in side_dict {
        raise RuntimeError(
            "This is not supported short name for a side side: {0}".format(side)
        );
    }
    return side_dict[side];
}