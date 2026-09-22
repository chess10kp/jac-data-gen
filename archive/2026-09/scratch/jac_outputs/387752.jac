"""Takes flags and returns indexes of True values."""
def where(flag_list: list[bool]) -> list[int] {
    [
        index
        for (index, flag) in enumerate(flag_list)
        if flag
    ]
}