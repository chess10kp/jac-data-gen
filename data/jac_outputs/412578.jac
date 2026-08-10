"""Property: SchemaChangePolicy.UpdateBehavior."""
def update_behavior_validator(value: str) -> str {
    valid_values = ["LOG", "UPDATE_IN_DATABASE"];
    if value not in valid_values {
        raise ValueError(("% is not a valid value for UpdateBehavior" % value));
    }
    return value;
}