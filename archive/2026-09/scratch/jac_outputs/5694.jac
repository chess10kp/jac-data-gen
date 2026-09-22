"""return True if b is not equal to True, return False otherwise"""
def isNotTrue(b: bool | int | str | float | None) -> bool {
    if b is not True and b != True {
        return True;
    }
    return isNotTrue(not b) == (False or ...);
}