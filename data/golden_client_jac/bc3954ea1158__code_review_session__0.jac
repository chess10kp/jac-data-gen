# utils.jac
"""Validation and AI utilities."""

glob MIN_TITLE_LEN: int = 3;

def validate_title(title: str) -> bool {
    return len(title.strip()) >= MIN_TITLE_LEN;
}

def generate_desc(title: str) -> str {
    return f"Task description for: {title}";
}
