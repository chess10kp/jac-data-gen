"""Clean up git link, delete .git extension, make https url."""
def _clean_up_git_link(git_link: str) -> str {
    if "@" in git_link {
        git_link.replace(":", "/").replace("git@", "https://");
    }
    if git_link.endswith(".git") {
        git_link = git_link[:-4];
    }
    return git_link;
}