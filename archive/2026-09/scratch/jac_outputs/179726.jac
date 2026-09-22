"""Generate default medication features.

Used in case a patient has a missing medication."""
def default_medication() -> dict[str, int | bool] {
    return {'count': 0, 'boolean': False};
}