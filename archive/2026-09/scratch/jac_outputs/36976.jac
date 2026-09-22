"""Load custom overrides from user."""
def load_custom_overrides(_: int, __: int, value: list[str]) -> dict[str, str] {
    user_overrides = {};
    for entry in value {
        (override_name, override_value) = entry.split('=');
        user_overrides[override_name] = override_value;
    }
    return user_overrides;
}