"""LLM prompts for the Portfolio Rebalance Agent."""

obj CandidateList {
    has candidates_json: str;
}

obj RebalanceResult {
    has gap_summary: str,
        picks_json: str;
}

"""You are a portfolio strategist. A portfolio has been analyzed and specific imbalances have been identified.

Given the existing portfolio tickers, the correlated theme, hedging gaps, and portfolio conviction issues,
generate 8-10 candidate securities (stocks or ETFs) that would address these imbalances.

For each candidate return a JSON array of objects with fields:
  ticker: the ticker symbol (must be a real, liquid US-listed security)
  asset_type: either "ETF" or "stock"
  gap_addressed: one sentence describing which specific gap this security addresses

Return ONLY valid JSON in candidates_json — a JSON array string like:
[{"ticker":"XLP","asset_type":"ETF","gap_addressed":"adds consumer defensive exposure to offset tech concentration"},...]

Rules:
- Only name tickers you are highly confident exist and are actively traded
- Match the asset type to the gap: broad sector/factor gaps → ETF, specific company exposure → stock
- Do not suggest tickers already in the existing portfolio
- Cover all identified gap types (sector, factor, hedge, conviction)
"""
def generate_candidates(
    existing_tickers: str,
    correlated_theme: str,
    hedging_gaps: str,
    portfolio_conviction: str,
    verdicts_summary: str
) -> CandidateList by llm();


"""You are a senior portfolio strategist doing final recommendation selection.

You have been given a list of candidate securities with their current technical signals.
Select the 3 best candidates to recommend as portfolio additions.

For each pick, provide:
  ticker: ticker symbol
  asset_type: "ETF" or "stock"
  gap_addressed: the gap this fills
  rationale: 2-3 sentences on why this fits and what the signals say about entry timing
  fit_score: integer 0-100 representing how well this fills the identified gap

Return results as JSON in picks_json — a JSON array of 3 objects with those exact fields.
Also provide gap_summary: a 1-2 sentence executive summary of the portfolio's primary imbalance.

Rules:
- Base rationale on the provided technical signals — do not invent price data
- Prefer picks with RSI between 40-60 (not overbought/oversold) for better entry timing
- Diversify across the identified gap types when possible
- Lower volatility is better for hedging picks, higher momentum for growth complements
"""
def rank_recommendations(
    candidates_with_signals: str
) -> RebalanceResult by llm();
