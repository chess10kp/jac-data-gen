"""convert a sequence of embedded sequences into a plain list"""
def flatten_seq(seq: dict[str, object] | list[object]) -> list[object] {
    result = [];
    vals = (seq as dict[str, object]).values() if `type(seq) == dict else seq;
    for i in vals {
        if `type(i) in (dict, list) {
            result.extend(flatten_seq(i as dict[str, object] | list[object]));
        } else {
            result.append(i);
        }
    }
    return result;
}