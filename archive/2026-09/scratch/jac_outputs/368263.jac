"""Converts standard true/false/none values to bools and None"""
def convert_booleans(kwargs: Any) -> object {
    for (key, value) in kwargs.items() {
        if not isinstance(value, str) {
            continue;
        }
        if (value.upper() == 'TRUE') {
            value = True;
        } elif (value.upper() == 'FALSE') {
            value = False;
        } elif (value.upper() == 'NONE') {
            value = None;
        }
        kwargs[key] = value;
    }
    return kwargs;
}