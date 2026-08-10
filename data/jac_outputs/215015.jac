"""Convert general string to github repo format string."""
def generate_repo_name(repo_name: str) -> str {
    repo_name.replace(" ", "-")
}