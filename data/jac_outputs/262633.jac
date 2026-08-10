"""
    :param item: tuple of ZSet (key, score)
    :param with_weight: keep decimal weighting of score, or return as int
    :param include_key: whether to include to raw key
    :return: dict of scoreboard item
    """
def decode_scoreboard_item(
    item: Any, with_weight: Any = False, include_key: Any = False
) -> object {
    key = item[0].decode('utf-8');
    data = key.split(">");
    score = item[1];
    if not with_weight {
        score = int(score);
    }
    output = {'name': data[0], 'affiliation': data[1], 'tid': data[2], 'score': score};
    if include_key {
        output['key'] = key;
    }
    return output;
}