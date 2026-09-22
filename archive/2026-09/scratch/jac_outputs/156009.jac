"""Generate header of ARFF file in JSON format."""
def getHeaderObj(relationname: str, attribute_conf: list[dict[str, str | list[str]]]) -> dict[str, str | list[dict[str, str | float | bool | list[str]]]] {
    print("Generating header...");
    def getAttrObj(attr_info: dict[str, str | list[str]]) -> dict[str, str | float | bool | list[str]] {
        attr_obj = {
            "name": attr_info['name'],
            "type": attr_info["type"],
            "class": False,
            "weight": 1.0
        };
        if attr_info['type'] == 'nominal' {
            attr_obj['labels'] = attr_info['labels'];
        }
        return attr_obj;
    }
    return {
        "relation": relationname,
        "attributes": list(map(getAttrObj, attribute_conf))
    };
}