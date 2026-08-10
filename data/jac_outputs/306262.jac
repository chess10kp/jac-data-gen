"""
    Take a dictionary of test data (suitable for comparison to an instance) and return a dict suitable for POSTing.
    """
def post_data(data: dict[str, str | int | float | bool | None | list | tuple]) -> dict[str, str | int | list | tuple] {
    ret: dict[str, str | int | list | tuple] = {};
    for (key, value) in data.items() {
        if value is None {
            ret[key] = '';
        } elif type(value) in (list, tuple) {
            if value and hasattr(value[0], 'pk') {
                ret[key] = [getattr(v, 'pk') for v in value];
            } else {
                ret[key] = value as list | tuple;
            }
        } elif hasattr(value, 'pk') {
            ret[key] = getattr(value, 'pk');
        } else {
            ret[key] = str(value);
        }
    }
    return ret;
}