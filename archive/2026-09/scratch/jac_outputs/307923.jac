"""
    Update ``config`` directory keys from the ``update`` directory, if the
    same key is not present in ``config``.

    Else merge the value from two keys if ``merge`` key argument is set to
    ``True``.
    """
def update_config(config: Any, update: Any, merge: Any = True) -> object {
    result = {};
    for (key, value) in config.items() {
        if ((key in update) and merge) {
            if isinstance(value, `dict) {
                result[key] = update_config(value, update[key]);
            } elif isinstance(value, `list) {
                result[key] = value + update[key];
            } else {
                result[key] = update[key];
            }
        } elif (key in update) {
            result[key] = update[key];
        } else {
            result[key] = value;
        }
    }
    for (key, value) in update.items() {
        if (key not in config) {
            result[key] = value;
        }
    }
    return result;
}