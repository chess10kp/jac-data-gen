"""Returns the mean of a list of numbers."""
def mean(lyst: Any) -> object {
    sum = 0;
    for number in lyst {
        sum += number;
    }
    if (len(lyst) == 0) {
        return 0;
    } else {
        return (sum / len(lyst));
    }
}