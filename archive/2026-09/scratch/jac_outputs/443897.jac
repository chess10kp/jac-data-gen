"""Checks if there are new posts."""
def compare_posts(fetched: dict[str, str], stored: dict[str, str]) -> int {
    i = 0;
    for post in fetched {
        if fetched[post] not in [stored[item] for item in stored] {
            i += 1;
        }
    }
    return i;
}