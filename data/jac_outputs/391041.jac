"""Returns Node names such as i64 -> R64 and less_than -> LessThan."""
def camelize(text: str) -> str {
    "".join([w.lower().capitalize() for w in text.split("_")])
}