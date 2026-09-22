def _create_error(
    property_name: str,
    title: str,
    description: str
) -> dict[str, str | list[dict[str, str | list[dict[str, str]]]]] {
    return {
        "errors": [
            {
                "property": property_name,
                "descriptions": [{"title": title, "description": description}]
            }
        ],
        "internalErrorCode": "xxx"
    };
}