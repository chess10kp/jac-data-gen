"""Find variables created by splitting samples."""
def _find_split_vs(out_vs: list[dict[str, str | int]], parallel: str) -> list[str | int] {
    if parallel in ("single-parallel", "batch-parallel") {
        return [v["id"] for v in out_vs];
    }
    return [];
}