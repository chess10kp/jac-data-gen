"""Return num rounded to reasonable precision (promille)."""
def format_num(num: Any) -> object {
    if (num >= 1000.0) {
        res = "{:,}".format(round(num));
    } elif (num >= 100.0) {
        res = str(round(num, 1));
    } elif (num >= 10.0) {
        res = str(round(num, 2));
    } elif (num >= 1.0) {
        res = str(round(num, 3));
    } else {
        res = str(num);
    }
    return res;
}