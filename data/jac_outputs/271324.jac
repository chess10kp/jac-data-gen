"""Make a dictionary from a list of keys"""
def make_dict(first: Any, rest: Any, data: Any) -> object {
    last = first;
    result = {first: data};
    current = result;
    for part in rest {
        current[last] = {};
        current = current[last];
        current[part] = data;
        last = part;
    }
    return result;
}