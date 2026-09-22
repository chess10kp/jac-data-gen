def _get_json_entry(json_object: dict[str, str], attribute_name: str, caller: str) -> str {
    if json_object.__contains__(attribute_name) {
        return json_object[attribute_name];
    }
    raise Exception('Cannot find attribute {} in {}.'.format(attribute_name, caller));
}