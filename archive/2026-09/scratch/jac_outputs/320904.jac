"""Take an object and find the first list."""
def find_data_list(data: list[str | int | float | bool] | dict[str, list[str | int | float | bool] | str | int | float | bool | None]) -> list[str | int | float | bool] {
    if isinstance(data, list) {
        return data;
    }
    if not isinstance(data, dict) {
        raise Exception("Loaded data type that we don't know what to do with");
    }
    print("Loaded dict with keys: %s" % data.keys());
    for (key, value) in data.items() {
        if isinstance(value, list) {
            print("Choosing key: `%s`" % key);
            return value;
        }
    }
    raise Exception("Loaded dict with no list values!");
}