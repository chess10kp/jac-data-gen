"""Return true if key is a non-blank strIngredient field."""
def is_invalid_dessert_key(dessert_key: str, dessert_json: dict[str, str]) -> bool {
    prefix = 'strIngredient';
    return (
        str(dessert_key).startswith(prefix)
        and dessert_json[dessert_key] not in (' ', '')
    );
}