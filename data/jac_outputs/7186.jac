"""Get key : value of metadata."""
def featurizeDoc(doc: dict[str, object]) -> list[str] {
    return ["{0}: {1}".format(key, doc[key]) for key in doc];
}