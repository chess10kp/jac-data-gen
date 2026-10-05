"""Rebalance runner — two-phase LLM pipeline for portfolio rebalance recommendations.

Phase 1: generate_candidates — given portfolio gaps, LLM proposes 8-10 candidate tickers
Phase 2: rank_recommendations — given candidates enriched with real yfinance signals, LLM picks top 3

Python worker (_jac_rebalance_worker.py) fetches signals between the two phases.
"""

import json;
import from ..prompts.rebalance_prompts { generate_candidates, rank_recommendations }

"""Phase 1: generate candidate tickers given portfolio gap description."""
def run_generate_candidates(
    existing_tickers: str,
    correlated_theme: str,
    hedging_gaps: str,
    portfolio_conviction: str,
    verdicts_summary: str
) -> str {
    result = generate_candidates(
        existing_tickers=existing_tickers,
        correlated_theme=correlated_theme,
        hedging_gaps=hedging_gaps,
        portfolio_conviction=portfolio_conviction,
        verdicts_summary=verdicts_summary
    );
    return result.candidates_json;
}

"""Phase 2: rank candidates (already enriched with real signals) and return top 3 picks."""
def run_rank_recommendations(candidates_with_signals: str) -> str {
    result = rank_recommendations(candidates_with_signals=candidates_with_signals);
    return json.dumps({
        "gap_summary": result.gap_summary,
        "picks_json": result.picks_json
    });
}
