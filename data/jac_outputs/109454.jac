"""Changes all dictionary values to yes whose keys are in the list."""
def _yes_format(user: dict[str, bool | str], keys: list[str]) -> dict[str, bool | str] {
    for key in keys {
        if user.get(key) {
            user[key] = 'yes';
        }
    }
    return user;
}