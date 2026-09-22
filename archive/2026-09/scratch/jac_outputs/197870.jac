"""Returns a sorted list of rule names from the rules list."""
def get_rule_names(rules: Any) -> object {
    return sorted([r['name'] for r in rules]);
}