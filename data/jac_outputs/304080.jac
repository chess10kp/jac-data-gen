"""Get a link in Markdown format."""
def get_md_link(text: str, link: str) -> str {
    f"[{text}]({link})"
}