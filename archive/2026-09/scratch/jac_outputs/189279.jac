"""
Gets the next slug from base_value such that "base_value-suffix" will not exceed max_length characters.
"""
def get_next_slug(base_value: str, suffix: int | str, max_length: int = 100) -> str {
    suffix_length = len(str(suffix)) + 1;
    if suffix_length >= max_length {
        raise ValueError("Suffix {} is too long to create a unique slug! ".format(suffix));
    }
    return '{}-{}'.format(base_value[:(max_length - suffix_length)], suffix);
}