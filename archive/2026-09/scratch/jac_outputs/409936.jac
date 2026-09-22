"""Return key list for nested structure.

    See: https://github.com/ducdetronquito/scalpl/issues/21#issue-700007850
    """
def get_nested_keys(data: Any) -> object {
    _null_key = object();
    def nested_key(data: Any) -> object {
        if isinstance(data, list) {
            keys = [];
            for i in range(len(data)) {
                result = nested_key(data[i]);
                if isinstance(result, list) {
                    if isinstance(data[i], dict) {
                        keys.extend([("[%d].%s" % (i, item)) for item in result]);
                    } elif isinstance(data[i], list) {
                        keys.extend([("[%d]%s" % (i, item)) for item in result]);
                    }
                } elif (result is _null_key) {
                    keys.append(("[%d]" % i));
                }
            }
            return keys;
        } elif isinstance(data, dict) {
            keys = [];
            for (key, value) in data.items() {
                result = nested_key(value);
                if isinstance(result, list) {
                    if isinstance(value, dict) {
                        keys.extend([("%s.%s" % (key, item)) for item in result]);
                    } elif isinstance(value, list) {
                        keys.extend([("%s%s" % (key, item)) for item in result]);
                    }
                } elif (result is _null_key) {
                    keys.append(("%s" % key));
                }
            }
            return keys;
        } else {
            return _null_key;
        }
    }
    keys = nested_key(data);
    if (keys is not _null_key) {
        return keys;
    }
    raise ValueError("invalid data type");
}