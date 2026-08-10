"""Custom version of numpy's linspace to avoid numpy depenency."""
def linspace(start: Any, stop: Any, num: Any) -> object {
    if (num == 1) {
        return stop;
    }
    h = (stop - start) / float(num);
    values = [(start + (h * i)) for i in range((num + 1))];
    return values;
}