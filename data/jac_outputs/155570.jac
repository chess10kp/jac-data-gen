"""Check if type exists in data pack."""
def type_exists(data: dict[str, list[dict[str, str]]], type_name: str) -> bool {
    for established_type in data['types'] {
        if established_type['name'] == type_name {
            return True;
        }
    }
    return False;
}