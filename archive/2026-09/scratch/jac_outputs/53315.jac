"""Pytest hook for user-friendly test name representation."""
def pytest_make_parametrize_id(
    config: bool,
    val: dict[str, str | dict[str, str]],
    argname: str
) -> str {
    """Unwrap dictionary to get all values of nested dictionaries."""
    def get_dict_values(d: dict[str, str | dict[str, str]] | str) -> list[str] {
        if isinstance(d, dict) {
            out = [];
            for v in d.values() {
                out = out + get_dict_values(v);
            }
            return out;
        }
        return [d];
    }
    keys = ["device", "model"];
    values_dict = {key: val[key] for key in keys};
    values = get_dict_values(values_dict);
    return "-".join(["_".join([key, str(v)]) for (key, v) in zip(keys, values)]);
}