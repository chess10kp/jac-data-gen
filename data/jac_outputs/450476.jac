"""Get nested index from collection."""
def nested_get(ind: int | list[int | list[int]], coll: str, lazy: bool = False) -> str | list[str] | list[list[str]] | Iterator[str | list[str] | list[list[str]]] {
    if isinstance(ind, list) {
        if lazy {
            return (nested_get(i, coll, lazy=lazy) for i in ind) as Iterator[str | list[str] | list[list[str]]];
        }
        return [nested_get(i, coll, lazy=lazy) for i in ind] as list[str] | list[list[str]];
    }
    return coll[ind];
}