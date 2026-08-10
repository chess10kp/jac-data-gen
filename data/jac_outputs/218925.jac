"""

    Get the item at the given path of keys by repeated [] lookups in obj.

    Work around https://github.com/BD2KGenomics/toil/issues/2214

    """
def lookup_key_path(job: object, `obj: object, path: list[object]) -> object {
    for key in path {
        `obj = `obj[key];
    }
    return `obj;
}