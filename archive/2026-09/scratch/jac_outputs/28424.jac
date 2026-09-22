"""Returns the maximum divider for `value` starting from `start` value"""
def get_div(value: int, start: int) -> int {
    div = 1;
    for d in range(start, 0, -1) {
        if value % d == 0 {
            div = d;
            break;
        }
    }
    return div;
}