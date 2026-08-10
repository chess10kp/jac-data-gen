"""internal method: used to convert values to a string suitable for an xml attribute"""
def _stringify(values: list[str] | tuple[str, ...] | bool | int | float | str) -> str {
    if `type(values) == list or `type(values) == tuple {
        return " ".join([str(x) for x in values]);
    } elif `type(values) == `type(True) {
        return "1" if values else "0";
    } else {
        return str(values);
    }
}