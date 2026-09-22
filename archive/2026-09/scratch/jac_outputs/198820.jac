"""Takes a dictionary of test data and returns a dict suitable for POSTing."""
def post_data(data: dict[str, object]) -> dict[str, str | int | list[int] | list | tuple] {
    r = {};
    for (key, value) in data.items() {
        if value is None {
            r[key] = "";
        } elif `type(value) in (list, tuple) {
            if value and hasattr(value[0], "pk") {
                r[key] = [getattr(v, "pk") for v in value];
            } else {
                r[key] = value;
            }
        } elif hasattr(value, "pk") {
            r[key] = getattr(value, "pk");
        } else {
            r[key] = str(value);
        }
    }
    return r;
}