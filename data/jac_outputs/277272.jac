"""
Flatten nested json to return a dict without nested values. Lists without nested values will
be ignored, and lists of dicts will only return the first key value pair for each key.
"""
def flatten_json(json: dict[str, dict | list | int | str | float | bool | None]) -> dict[str, int | str | float | bool | None] {
    out: dict[str, int | str | float | bool | None] = {};
    def flatten(x: dict | list | int | str | float | bool | None, name: str = '') {
        if type(x) is dict {
            for (k, v) in (x as dict[str, dict | list | int | str | float | bool | None]).items() {
                flatten(v, k);
            }
        } elif type(x) is list {
            for a in (x as list[dict | list | int | str | float | bool | None]) {
                flatten(a);
            }
        } elif name != '' and name not in out {
            out[name] = x as int | str | float | bool | None;
        }
    }
    flatten(json);
    return out;
}