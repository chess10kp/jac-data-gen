"""Utility function to find the size of a system parameter

    If both parameters are not None, they must be consistent.
    """
def _find_size(sysval: int | None, vecval: int | list[int] | str | None) -> int {
    if hasattr(vecval, '__len__') {
        if sysval is not None and sysval != len(vecval) {
            raise ValueError(
                "Inconsistend information to determine size " "of system component"
            );
        }
        return len(vecval);
    }
    if not vecval {
        return 0 if sysval is None else sysval;
    } elif sysval == 1 {
        return 1;
    }
    raise ValueError("Can't determine size of system component.");
}