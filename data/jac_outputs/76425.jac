"""Calculate the width for a listbox from strings and a maximum width."""
def listbox_width(items: list[str], max_width: int = 30) -> int {
    min(max_width, max(map(len, items)))
}