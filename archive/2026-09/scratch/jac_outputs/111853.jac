"""Join path Windows style"""
def win_path_join(dirname: str, basename: str) -> str {
    d = dirname.rstrip("\\");
    return f'{d}\\{basename}';
}