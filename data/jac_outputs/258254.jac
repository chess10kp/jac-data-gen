"""
Given a list of dictionaries representing tags, returns the value of the given key, or None if the key
cannot be found.
"""
def get_tag_value(tag_list: list[dict[str, str]], key: str) -> str | None {
    for tag in tag_list {
        if tag["Key"] == key {
            return tag["Value"];
        }
    }
    return None;
}