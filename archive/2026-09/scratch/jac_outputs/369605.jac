"""If the keys of dict2 are a subset of the keys of dict1,
return a copy of dict1 updated with the values of dict2,
otherwise return an empty dict of the same type as dict1."""
def subset_or_none(dict1: dict[str, object], dict2: dict[str, object]) -> dict[str, object] {
    new_dict = dict1.copy();
    new_dict.update(dict2);
    if new_dict.keys() == dict1.keys() {
        return dict1.__class__(new_dict);
    }
    return dict1.__class__();
}