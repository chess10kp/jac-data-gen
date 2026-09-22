"""Interpret a string as an orientation value (lr, rl, tb, or bt)."""
def str_to_orientation(
    value: str, reversed_horizontal: bool = False, reversed_vertical: bool = False
) -> str {
    aliases = {
        "left-right": "lr",
        "right-left": "rl",
        "top-bottom": "tb",
        "bottom-top": "bt",
        "top-down": "tb",
        "bottom-up": "bt",
        "td": "tb",
        "bu": "bt"
    };
    dir = ["lr", "rl"][reversed_horizontal];
    aliases.update(horizontal=dir, horiz=dir, h=dir);
    dir = ["tb", "bt"][reversed_vertical];
    aliases.update(vertical=dir, vert=dir, v=dir);
    result = aliases.get(value, value);
    if result not in ("lr", "rl", "tb", "bt") {
        raise ValueError(f"unknown orientation: {result}");
    }
    return result;
}