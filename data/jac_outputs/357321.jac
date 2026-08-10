"""Create an 'update' dictionary for update_workspace_attributes()."""
def _attr_set(attr: str, value: str | int | float | bool | None) -> dict[str, str | int | float | bool | None] {
    return {
        "op": "AddUpdateAttribute",
        "attributeName": attr,
        "addUpdateAttribute": value
    };
}