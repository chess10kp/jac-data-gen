import from pathlib { Path }

"""convert Pathlib object to absolute path as string"""
def pltostr(path: str | Path) -> str {
    if isinstance(path, str) {
        return path;
    }
    return str(path.absolute());
}