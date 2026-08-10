"""Aggregate state total financial outlay for FRT."""
def _sum_state_financial_outlay(results: list[dict[str, float]] | None) -> float {
    if results is None {
        return 0;
    }
    total_financial_outlay = 0.0;
    for result in results {
        if result['financial_outlay_cr'] {
            total_financial_outlay += result['financial_outlay_cr'];
        }
    }
    return total_financial_outlay;
}