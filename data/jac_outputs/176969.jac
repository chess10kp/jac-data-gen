"""Return the validation message shown for an empty preference."""
def get_empty_preference_message(preference_key: str) -> str {
    f"Preference '{preference_key}' cannot be set to an empty value."
}