"""Transforms tokensregex and semgrex matches to indexed words.
    :param matches: unprocessed regex matches
    :return: flat array of indexed words
    """
def regex_matches_to_indexed_words(matches: dict[str, list[dict[str, dict]]]) -> list[dict] {
    return [
        dict(v, **{'sentence': i})
        for (i, s) in enumerate(matches['sentences'])
        for (k, v) in s.items()
        if k != 'length'
    ];
}