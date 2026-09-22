"""Test if a git command."""
def is_git(cmd: str) -> bool {
    return cmd.endswith("git-bln");
}