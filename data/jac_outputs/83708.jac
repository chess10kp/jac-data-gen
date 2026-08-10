"""Restore args with whitespace, to support file paths with whitespace"""
def restore_args_with_whitespace(x: Any) -> object {
    y = [];
    for xi in x {
        if (len(y) == 0) {
            y.append(xi);
        } elif y[-1].endswith('\\') {
            y[-1] = y[-1][0:-1] + ' ' + xi;
        } else {
            y.append(xi);
        }
    }
    return y;
}