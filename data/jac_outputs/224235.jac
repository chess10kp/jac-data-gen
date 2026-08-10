"""Create flat list of tweet text from list of dict or list of list."""
def flatten_twdict(twlist: list[dict[str, str] | list | str]) -> list[str] {
    result: list[str] = [];
    for item in twlist {
        if isinstance(item, dict) {
            result.append(item['text']);
        } elif isinstance(item, list) {
            result.append(" ".join([str(x) for x in item]));
        } else {
            result.append(item);
        }
    }
    return result;
}