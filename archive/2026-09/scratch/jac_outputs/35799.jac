"""Return inferred property name from pandas column name."""
def infer_prop_name(name: str) -> str {
    return name.strip(' "').rsplit('(', 1)[0].rsplit('[', 1)[0].strip().replace(' ', '_');
}