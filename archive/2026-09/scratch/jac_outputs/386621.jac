""" Format the stats for each term into a compact tuple"""
def justTfandDf(terms: dict[str, dict[str, int]]) -> dict[str, tuple[int, int]] {
    return {term: (value['term_freq'], value['doc_freq']) for (term, value) in terms.items()};
}