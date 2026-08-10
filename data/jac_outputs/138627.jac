"""Validates if all Stop Condition names are unique."""
def get_duplicated_sc_names(validated_data: dict[str, list[dict[str, str]]]) -> list[str] | set[str] {
    sc_names = [sc["Name"] for sc in validated_data["StopCondition"]];
    duplicates: list[str] | set[str] = [];
    if len(sc_names) > len(set(sc_names)) {
        duplicates = set(x for x in sc_names if sc_names.count(x) > 1);
    }
    return duplicates;
}