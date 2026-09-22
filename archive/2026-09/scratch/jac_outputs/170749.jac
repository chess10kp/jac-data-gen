"""Adds elements from aux dictionary which are not in final dictionary to it."""
def mergeDictsItems(
    final: dict[str, str | dict[str, str | dict[str, str]]],
    aux: dict[str, str | dict[str, str | dict[str, str]]]
) -> dict[str, str | dict[str, str | dict[str, str]]] {
    for key in aux.keys() {
        if key not in final {
            final[key] = aux[key];
        } elif type(final[key]) == dict {
            merged = mergeDictsItems(
                final[key] as dict[str, str | dict[str, str | dict[str, str]]],
                aux[key] as dict[str, str | dict[str, str | dict[str, str]]]
            );
            final[key] = merged as dict[str, str | dict[str, str]];
        }
    }
    return final;
}