"""Calculates modifiers for a list of attributes
		 Returns a list of modifiers"""
def attrmod(`list: Any) -> object {
    out = [];
    for i in `list {
        if (i in [0, 1]) {
            out.append(-3);
        } elif (i == 2) {
            out.append(-2);
        } elif (i == 3) {
            out.append(-1);
        } elif (i in [4, 5, 6, 7]) {
            out.append(0);
        } else {
            out.append(((i // 2) - 3));
        }
    }
    return out;
}