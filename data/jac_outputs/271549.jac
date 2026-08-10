"""convert raw address value to string"""
def stringifyList(rowVal: str | list[str] | int) -> str | list[str] | int {
    if isinstance(rowVal, list) {
        return ", ".join(str(x) for x in rowVal);
    }
    return rowVal;
}