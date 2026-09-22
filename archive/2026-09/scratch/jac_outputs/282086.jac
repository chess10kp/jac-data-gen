"""
Returns True if values in classes are anything but 1, 0, True, or False,
otherwise returns False.
"""
def is_multiclass(classes: list[int | str | bool]) -> bool {
    try {
        return len(set(int(i) for i in classes) - {0, 1}) != 0;
    } except ValueError {
        return True;
    }
}