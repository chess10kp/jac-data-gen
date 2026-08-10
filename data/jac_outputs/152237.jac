"""Returns the percent change of diverity between normal recommendations vs. diverse recommendations."""
def compare_diversity(avg_dissim_algo: int, avg_dissim_control: int) -> float {
    percent_change = ((avg_dissim_algo - avg_dissim_control) / avg_dissim_control) * 100;
    return round(percent_change, 2);
}