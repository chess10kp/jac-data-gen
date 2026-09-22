"""Organize data by class."""
def data_by_class(data: list[dict[str, int | str]]) -> dict[int | str, list[dict[str, int | str]]] {
    dbc = {};
    for item in data {
        if item["symbol_id"] in dbc {
            dbc[item["symbol_id"]].append(item);
        } else {
            dbc[item["symbol_id"]] = [item];
        }
    }
    return dbc;
}