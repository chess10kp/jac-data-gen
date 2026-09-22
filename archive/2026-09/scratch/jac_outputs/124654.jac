"""Check if the freq is unmethylated, means 0.0 (almost)."""
def is_fully_unmeth(methfreq: float, eps: float = 1e-05) -> bool {
    if methfreq > 1.0 + eps or methfreq < 0 {
        raise Exception(f'detect error value for freq={methfreq}');
    }
    return methfreq < eps;
}