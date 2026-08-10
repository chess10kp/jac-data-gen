"""
    Limit v to the range 1-8 or None, with 0 being converted to 8 (straight ahead).

    This is necessary because the back-calculation to degree7 will negative values
    yet the input to calculate_average_instruction must use 1-8 to weight forward
    instructions correctly.
    """
def map1to8(v: int | None) -> int | None {
    if v is None or v > 0 {
        return v;
    }
    return v + 8;
}