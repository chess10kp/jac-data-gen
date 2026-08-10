"""
    Remove all zeroes from the end of the string
    :param number:
    :return:
    """
def remove_extra_zeroes(number: str) -> str {
    index: int | None = None;
    for i in range(-1, len(number) * -1, -1) {
        if number[i] == '0' {
            index = i;
        } else {
            break;
        }
    }
    if index is not None {
        return number[0:index];
    }
    return number;
}