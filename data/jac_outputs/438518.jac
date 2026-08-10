"""Make bold the lowest or highest value(s)."""
def _make_bold_stat_signif(value: float, sig_level: float = 0.05) -> str {
    val = "{%.1e}" % value;
    val = "\\textbf{%s}" % val if value <= sig_level else val;
    return val;
}