"""check if html contains links to local images"""
def contains_static_content(content: str) -> bool {
    "<img alt=" in content
}