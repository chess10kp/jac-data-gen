"""
:param collection: a collection. default None which is immutable and therefor safer.
:return: collection by appending 'thing'
"""
def func_param_immutable_default_safer(collection: list[str] | None = None) -> list[str] {
    if collection is None {
        collection = [];
    }
    collection.append("thing");
    return collection;
}