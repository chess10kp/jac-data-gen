"""Makes link in discord message display without embedded website preview."""
def no_embed_link(url: str) -> str {
    return f"<{url}>";
}