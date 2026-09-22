"""Produces an about node based on DDC."""
def handle_single_ddc(data: str) -> dict[str, str | dict[str, str]] {
    return {
        "identifier": {"@type": "PropertyValue", "propertyID": "DDC", "value": data},
        "@id": "http://purl.org/NET/decimalised#c" + data[:3]
    };
}