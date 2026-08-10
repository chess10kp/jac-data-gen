"""Perform some simple manipulations."""
def marriage_transform(m_s_string: str) -> str {
    if m_s_string.startswith("Married") {
        return "Medium";
    } elif m_s_string.startswith("Widowed") {
        return "High";
    }
    return "Low";
}