"""
    Jaccard similarity score
    The Jaccard coefficient measures similarity between finite sample sets, and
    is defined as the size of the intersection divided by the size of the union
    of the sample sets

    https://en.wikipedia.org/wiki/Jaccard_index

    :param input_gene_list:
    :param background_gene_list:
    :return:
    """
def jaccard_score(list1: list[str], list2: list[str]) -> float {
    n = len(set(list1).intersection(list2));
    d = len(set(list1).union(list2));
    if d == 0 {
        return 0;
    }
    return 1.0 * n / d;
}