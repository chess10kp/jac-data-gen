"""Return reveresed dictionary."""
def get_reversed_dictionary(dictionary: dict[str, str], keys: list[str]) -> dict[str, str] {
    return {
        v: k
        for k in keys
        if (v := dictionary.get(k))
    };
}