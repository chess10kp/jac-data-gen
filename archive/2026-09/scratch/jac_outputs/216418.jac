"""Returns the font size for a word."""
def get_size(count: int, count_min: int, count_max: int, options: dict[str, int]) -> int {
    result = options["FONTSIZE_MAX"];
    if count_min != count_max {
        ratio = count / float(count_max - count_min);
        lo = options["FONTSIZE_MIN"];
        hi = options["FONTSIZE_MAX"];
        result = int(lo + (hi - lo) * min(1.0, ratio ** 0.2));
    }
    return result;
}