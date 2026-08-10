"""Internal mapping type checker

    Instead of using `isinstance(obj, MutableMapping)`, duck type checking
    is much cheaper and work on most common use cases.

    If an object has these attritubes, is a document:
        `__len__`, `keys`, `values`

    """
def is_duckument_type(`obj: Any) -> object {
    doc_attrs = ("__len__", "keys", "values");
    return all(hasattr(`obj, attr) for attr in doc_attrs);
}