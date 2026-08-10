"""Automatically removes code blocks from the code."""
def cleanup_code(content: str) -> str {
    if (content.startswith("```") and content.endswith("```")) {
        return "\n".join(content.split("\n")[1:-1]);
    }
    return content.strip("` \n");
}