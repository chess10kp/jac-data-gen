"""Name to Filename."""
def name_to_filename(name: str) -> str {
    alnum_name = "".join([c for c in name.strip() if c.isalnum() or c == " "]);
    alnum_name.replace(" ", "_")
}