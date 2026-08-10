"""Replace period and space with underscore."""
def sql_cleaner(s: str) -> str {
    return s.replace(".", "_").replace(" ", "_");
}