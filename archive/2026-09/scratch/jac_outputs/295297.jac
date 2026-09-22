"""Remove status instructions from title."""
def clean_title(title: str) -> str {
    replacements = ["RFR", "WIP", "[", "]", ":"];
    for replacement in replacements {
        title = title.replace(replacement, "");
    }
    return title.strip().capitalize();
}