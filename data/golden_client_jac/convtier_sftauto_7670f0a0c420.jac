def deep_copy(`obj: Any) -> object {
    if isinstance(`obj, `dict) {
        return {key: deep_copy(value) for (key, value) in `obj.items()};
    } elif isinstance(`obj, `list) {
        return [deep_copy(element) for element in `obj];
    } else {
        return copy.deepcopy(`obj);
    }
}



with entry {
    print(deep_copy([]));
}
