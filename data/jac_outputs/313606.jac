"""Serialize objects: preserve list/dict structure, convert everything else to string."""
def string_serializer(`obj: list[object] | tuple[object] | dict[object, object] | str | int | float | bool) -> list[object] | dict[object, object] | str {
    if type(`obj) in [list, tuple] {
        return list(map(string_serializer, `obj));
    }
    if type(`obj) == dict {
        dict_obj = `obj as dict[object, object];
        copy: dict[object, object] = {};
        for (k, v) in dict_obj.items() {
            copy[k] = string_serializer(v as list[object] | tuple[object] | dict[object, object] | str | int | float | bool);
        }
        return copy;
    }
    return str(`obj);
}