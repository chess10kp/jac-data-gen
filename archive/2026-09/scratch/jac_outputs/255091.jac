"""Display the specified number as a badge."""
def badge(value: int | float | None, bg_color: str | None = None, show_empty: bool = False) -> dict[str, int | float | str | bool | None] {
    return {
        'value': value,
        'bg_color': bg_color or 'secondary',
        'show_empty': show_empty
    };
}