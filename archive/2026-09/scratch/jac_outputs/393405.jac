"""Customised label skipping for 14 quantiles."""
def skip_14(labels: list[str]) -> tuple[str, str, str, str, str, str, str] {
    return (
        labels[0],
        labels[2],
        labels[4],
        labels[6],
        labels[8],
        labels[10],
        labels[13]
    );
}