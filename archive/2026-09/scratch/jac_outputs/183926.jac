"""Validate manager option input; returns success flag and selected value."""
def validate_manager_options(user_input: str) -> tuple[bool, str | None] {
    switcher = {'0': (True, '0'), '1': (True, '1'), '2': (True, '2')};
    return switcher.get(user_input, (True, None));
}