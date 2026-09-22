"""
    Returns the size of a deeply nested object (dict/list/set).
    The size of each leaf (non-dict/list/set) is 1.
    """
def objsize(`obj: Any) -> object {
    assert isinstance(`obj, (dict, list, set)) , `obj;
    if not `obj {
        return 0;
    }
    if isinstance(`obj, dict) {
        `obj = `obj.values();
    }
    elem = next(iter(`obj));
    if isinstance(elem, (dict, list, set)) {
        return sum(objsize(v) for v in `obj);
    } else {
        return len(`obj);
    }
}