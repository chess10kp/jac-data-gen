"""Remove commas from a float"""
def clean_float(v: str | int | float | None) -> float | None {
    if v is None or not str(v).strip() {
        return None;
    }
    return float(str(v).replace(',', '').replace(' ', ''));
}