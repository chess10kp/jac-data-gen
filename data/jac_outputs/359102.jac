"""Return the path of the field in a dict."""
def json_get(item: dict, path: str, `default: str | int | float | bool | dict | list | None = None) -> str | int | float | bool | dict | list | None {
    tab = path.split(".");
    if tab[0] in item {
        if len(tab) > 1 {
            return json_get(item[tab[0]], ".".join(tab[1:]), `default=`default);
        }
        return item[tab[0]];
    }
    return `default;
}