"""Convert SQL fetchall single-column tuple list to a regular list."""
def QueryTupleListToList(var: list[tuple[object, ...]]) -> list[object] {
    result = [];
    for i in var {
        result.append(i[0]);
    }
    return result;
}