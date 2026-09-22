"""Given a dictionary, returns a new one retaining only pairs satisfying the predicate."""
def filter_dict(kv: dict[str, int], p: Callable[[str, int], bool]) -> dict[str, int] {
    {
        k: v
        for (k, v) in kv.items()
        if p(k, v)
    }
}