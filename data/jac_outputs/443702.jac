"""Change the property name "@type" to "thing_type" and "id" to "thing_id" in the thing_description."""
def clean_thing_description(thing_description: dict[str, object]) -> dict[str, object] {
    if "@type" in thing_description {
        thing_description["thing_type"] = thing_description.pop("@type");
    }
    if "id" in thing_description {
        thing_description["thing_id"] = thing_description.pop("id");
    }
    return thing_description;
}