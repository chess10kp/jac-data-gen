"""Return exponent string. An empty string if exponent is 1.
    """
def exp_str(dictionary: dict[str, int], key: str) -> str {
    if dictionary[key] == 1 {
        return '';
    }
    return '**' + str(dictionary[key]);
}