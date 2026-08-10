"""2.54cm => 72pt (1 inch)."""
def cm2pt(cm: float = 1) -> float {
    float(cm) * 72.0 / 2.54
}