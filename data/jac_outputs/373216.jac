"""Make the url for filestats data in heron-shell from the info stored in stmgr."""
def make_shell_filestats_url(host: str, shell_port: int, path: str) -> str {
    return f"http://{host}:{shell_port}/filestats/{path}";
}