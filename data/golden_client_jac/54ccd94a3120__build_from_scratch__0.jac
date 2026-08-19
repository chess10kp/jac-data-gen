def _fmt_row(label: str, d: BenchResult | None) -> str {
    return label + "  " + str(d.avg) + "  " + str(d.max) + "  " + str(d.frames);
}
