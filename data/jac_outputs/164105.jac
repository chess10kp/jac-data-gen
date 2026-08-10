"""Convert an OrderedDict to a serialized list-of-tuples string."""
def ordered_dict_to_pref(`obj: object, member: object, val: dict[str, object]) -> str {
    return repr(list(val.items()));
}