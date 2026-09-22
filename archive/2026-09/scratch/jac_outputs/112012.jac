"""
    given a list, return a list enumerated with prefix.
    """
def enumerate_with_prefix(a_list: list[str], prefix: str = 'pre_') -> list[str] {
    num_digits = len(str(len(a_list)));
    return [
        prefix + str(idx).zfill(num_digits) for (idx, el) in enumerate(a_list)
    ];
}