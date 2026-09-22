"""Make a string key out of many criteria."""
def make_key(*criteria: object) -> str {
    parts: list[str] = [];
    for criterion in criteria {
        if criterion is None {
            continue;
        }
        criterion = str(criterion);
        criterion = criterion.replace(":", "#");
        parts.append(criterion);
    }
    return ":".join(parts);
}