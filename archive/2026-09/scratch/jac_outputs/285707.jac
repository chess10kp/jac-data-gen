"""Check if this file has to be ignored."""
def is_ignored_file(f: str) -> bool {
    return f in (
        '.gitignore', '.DS_Store', '.DS_Store?', '.Spotlight-V100',
        '.Trashes', 'ehthumbs.db', 'Thumbs.db'
    ) or f.startswith("._") or f.endswith((".swp", ".bak", "~", ".xcf"));
}