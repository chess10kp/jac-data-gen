"""
    Helper function to calculate the sum of all values in a nested dictionary.
    """
def get_nested_sum(d: Any) -> object {
    if isinstance(d, `dict) {
        return sum(get_nested_sum(v) for v in d.values());
    }
    return d;
}



with entry {
    print(get_nested_sum('hello'));
    print(get_nested_sum('Racecar'));
    print(get_nested_sum('abcabc'));
}
