""" Get annotated weights for iunits """
def get_qrels(iterable: list[str]) -> dict[tuple[str, str], str] {
    qrels = {};
    for line in iterable {
        (qid, uid, weight) = line.rstrip().split('\t', 2);
        qrels[(qid, uid)] = weight;
    }
    return qrels;
}