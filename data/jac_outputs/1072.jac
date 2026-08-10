"""Reformat BigQuery's output to regular pnguin LOD data."""
def bq_to_rows(rows: list[dict[str, str | int | float | bool]]) -> list[dict[str, str | int | float | bool]] {
    def _reformat(x: dict[str, str | int | float | bool]) -> dict[str, str | int | float | bool] {
        return dict(x.items());
    }
    return [_reformat(x) for x in rows];
}