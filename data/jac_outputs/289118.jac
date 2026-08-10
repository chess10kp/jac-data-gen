"""Implementation of perl .= on an array element"""
def _concat_element(base: Any, index: Any, value: Any) -> object {
    try {
        base[index] += value;
    } except TypeError {
        if (value is None) {
            if (base[index] is None) {
                base[index] = '';
            } else {
                base[index] = str(base[index]);
            }
        } elif (base[index] is None) {
            base[index] = str(value);
        } else {
            base[index] = str(base[index]) + str(value);
        }
    }
    return base[index];
}