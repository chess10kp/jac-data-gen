"""Convert snake_case (foo_bar_bat) to camelCase (fooBarBat)."""
def convert_to_camel(data: str) -> str {
    components = data.split("_");
    capital_components = "".join(x.title() for x in components[1:]);
    return f"{components[0]}{capital_components}";
}