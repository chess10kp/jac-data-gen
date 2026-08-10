"""
For getting an item from a dictionary in a template using a variable.
Use like:
    {{ mydict|get_item:my_var }}
"""
def get_item(dictionary: dict[object, object], key: object) -> object | None {
    return dictionary.get(key);
}