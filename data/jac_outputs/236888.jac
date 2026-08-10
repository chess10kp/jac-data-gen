""" Looks like a Pandas Index. ** Borrowed from dask.dataframe.utils ** """
def is_index_like(s: object) -> bool {
    typ = `type(s);
    return (
        all(hasattr(s, name) for name in ("name", "dtype"))
        and "index" in typ.__name__.lower()
    );
}