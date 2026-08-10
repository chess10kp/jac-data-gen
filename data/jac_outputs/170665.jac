"""Seperates the various parts of git commit messages."""
def parse_commit_info(
    git_log: str,
    git_commit_fields: tuple[str, ...] = ('id', 'body', 'author', 'timestamp', 'subject')
) -> list[dict[str, str]] {
    git_log_cmds = git_log.strip('\n\x1e').split("\x1e");
    git_log_rows = [row.strip().split("\x1f") for row in git_log_cmds];
    return [dict(zip(git_commit_fields, row)) for row in git_log_rows];
}