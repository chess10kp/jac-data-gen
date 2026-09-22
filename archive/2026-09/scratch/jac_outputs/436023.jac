"""Take the maximum of dictionaries."""
def dict_max(*ds: dict[str, int]) -> dict[str, int] {
    if not all(set(d.keys()) == set(ds[0].keys()) for d in ds[1:]) {
        raise ValueError("Dictionaries have different keys.");
    }
    return {k: max([d[k] for d in ds]) for k in ds[0].keys()};
}