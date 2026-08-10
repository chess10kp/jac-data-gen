"""Changes performance timing results to deltas."""
def parse_performance_timing(p_timing: dict[str, int | None]) -> dict[str, int] {
    ns = p_timing["navigationStart"];
    return {k: (v - ns) if v else 0 for (k, v) in p_timing.items()};
}