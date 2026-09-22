"""Fetch the specified key from list of dictionary. Key is identified via the key field."""
def fetch_param_value(response: Any, key: Any, key_field: Any) -> object {
    for param in response {
        if (param[key_field] == key) {
            return param["Value"];
        }
    }
}