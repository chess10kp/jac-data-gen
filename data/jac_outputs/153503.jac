"""Canonical xml float value output"""
def fstr(value: Any) -> object {
    int_value = int(value);
    if (int_value == value) {
        return str(int_value);
    }
    return str(value);
}