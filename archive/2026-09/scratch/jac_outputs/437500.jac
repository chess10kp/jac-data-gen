"""Return (name, id) pair depending on whether input is a name or id."""
def extract_name_and_id(user_input: str) -> tuple[str | None, str | None] {
    name = id = None;
    if user_input.lower().startswith('id:') {
        id = user_input[3:];
    } else {
        name = user_input;
    }
    return (name, id);
}