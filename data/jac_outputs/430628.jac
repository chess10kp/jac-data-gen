"""Returns True if the item is a runway visibility range string"""
def is_runway_visibility(item: str) -> bool {
    return len(item) > 4
        and item[0] == "R"
        and (item[3] == "/" or item[4] == "/")
        and item[1:3].isdigit();
}