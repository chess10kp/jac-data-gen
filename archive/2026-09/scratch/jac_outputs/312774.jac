"""Return a histogram of integers as a list of counts."""
def hist_int(array: list[int]) -> list[int] {
    hist = [0] * (max(array) + 1);
    negative = [];
    for i in array {
        if i >= 0 {
            hist[i] += 1;
        } else {
            negative.append(i);
        }
    }
    return hist;
}