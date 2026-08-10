"""Validate an eye color."""
def validate_eye_color(eye_color: str) -> bool {
    eye_color in ("amb", "blu", "brn", "gry", "grn", "hzl", "oth")
}