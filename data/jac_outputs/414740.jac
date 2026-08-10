"""
We need to distinguish between no baseline mode (which should return
None as a value), baseline mode with exceeded timeout (which is stored
as None, but should return 0).
"""
def _get_baseline_value(baseline: dict[str, int | None], key: str) -> int | None {
    if key in baseline {
        return 0 if baseline[key] is None else baseline[key];
    }
}