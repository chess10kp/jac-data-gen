"""
Get an attribute from a dictionary given its key name.
Returns default if the attribute is not present.
"""
def get(
    attribute_name: str,
    json_response: dict[str, str | int | float | bool | list | dict | None] | None,
    `default: str | int | float | bool | list | dict | None = None
) -> str | int | float | bool | list | dict | None {
    return `default
        if not json_response or attribute_name not in json_response
        else json_response[attribute_name];
}