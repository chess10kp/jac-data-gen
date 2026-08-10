"""
    Transforms a count dictionary in an ordered feature vector.
    """
def get_bigram_data(bigram_dict: dict[tuple[str, str], int], combinations_list: list[tuple[str, str]]) -> list[int] {
    return [bigram_dict.get(combi, 0) for combi in combinations_list];
}