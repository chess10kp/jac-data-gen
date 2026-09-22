"""Return property value from expanded JSON-LD data."""
def _get_jsonld_property(
    jsonld: dict[str, str | int | float | bool | list | dict | None],
    property: str,
    `default: str | int | float | bool | list | dict | None = None
) -> str | int | float | bool | list | dict | None {
    value = jsonld.get(property);
    if not value {
        return `default;
    }
    if (
        isinstance(value, list)
        and len(value) == 1
        and isinstance(value[0], dict)
        and "@value" in value[0]
    ) {
        value = value[0]["@value"] as str | int | float | bool | list | dict | None;
    }
    return value;
}