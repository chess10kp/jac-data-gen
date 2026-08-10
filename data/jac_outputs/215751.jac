"""Add support for aliasing to make some names shorter & allow minor mistakes."""
def alias(name: str) -> str {
    aliases = {
        "cpp": "c++",
        "jb": "jetbrains",
        "javascript": "node",
        "js": "node",
        "py": "python"
    };
    return aliases.get(name, name);
}