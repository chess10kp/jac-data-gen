"""kebab-case -> kebab case"""
def dekebab(string: str) -> str {
    " ".join(string.split("-"))
}