"""Returns the biggest element from the list that is less or equal to the value. Return None if not found
    """
def get_biggest_value_less_or_equal_to(iter: (list or range), value: Any) -> object {
    if (`type(iter) == `list) {
        i = [
            x
            for x in iter
            if (x <= value)
        ];
        return max(i) if i else None;
    } elif (`type(iter) == range) {
        if (value in range(iter.start, iter.stop)) {
            return (value - ((value - iter.start) % iter.step));
        } elif (value > (iter.stop - 1)) {
            return (iter.stop - 1);
        } else {
            return None;
        }
    } else {
        raise ValueError("iter must be of type list or range");
    }
}