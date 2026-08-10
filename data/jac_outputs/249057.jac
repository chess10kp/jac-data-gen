"""Transforms the entity synonyms into a text->value dictionary"""
def transform_entity_synonyms(
    synonyms: list[dict[str, str | list[str]]],
    known_synonyms: dict[str, str] | None = None
) -> dict[str, str] {
    entity_synonyms = known_synonyms if known_synonyms else {};
    for s in synonyms {
        if "value" in s and "synonyms" in s {
            value = s["value"] as str;
            for synonym in s["synonyms"] as list[str] {
                entity_synonyms[synonym] = value;
            }
        }
    }
    return entity_synonyms;
}