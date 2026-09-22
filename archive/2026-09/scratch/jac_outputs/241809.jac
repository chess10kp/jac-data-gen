"""add last updated liveblog timestamp"""
def add_last_timestamp(posts: list[dict[str, str]]) -> str | None {
    timestamp = None;
    if posts {
        timestamp = posts[0]['timestamp'];
    }
    return timestamp;
}