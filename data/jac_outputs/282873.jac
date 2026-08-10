"""
    Build header.
    """
def build_header(src: str, episode_url: str) -> dict[str, str] {
    return {'Referer': episode_url};
}