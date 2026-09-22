"""Convert the :members: options to class directive."""
def _parse_members(argument: str | None) -> bool | list[str] {
    if argument is None {
        return True;
    }
    return [arg.strip() for arg in argument.split(",")];
}