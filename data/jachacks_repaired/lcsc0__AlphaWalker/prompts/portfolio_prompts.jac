"""LLM prompts for the Portfolio Meta Agent."""

obj PortfolioInsight {
    has annotation: str,
        correlated_theme: str,
        hedging_gaps: str,
        portfolio_conviction: str;
}

"""Synthesize a portfolio-level annotation from per-asset summaries.

You are a senior portfolio strategist reviewing an entire portfolio after
individual asset analyses are complete. Your job is to surface cross-asset
patterns that no single-ticker analyst can see.

You will receive a text block with one line per asset containing:
ticker, sector, bull argument, bull confidence, bear argument, bear confidence,
judge verdict, and judge confidence.

Analyze four dimensions:

1. CONCENTRATION RISK — Identify sector, factor, or geographic clustering.
   Name specific tickers and compute approximate portfolio weight percentages.
   Example: "NVDA, AMD, AMAT represent 45% of holdings — all semiconductors."

2. CORRELATED BULL SIGNALS — When multiple holdings are bullish for the same
   underlying reason (e.g. AI capex, rate cuts, consumer strength), that is a
   single macro bet expressed multiple ways, not diversification. Name the
   shared thesis and the tickers it applies to.

3. HEDGING GAPS — Identify positions that should offset each other but don't,
   given current signals. If the portfolio lacks natural hedges against its
   dominant thesis, say so.

4. PORTFOLIO-LEVEL CONVICTION — Do the per-ticker judge verdicts add up to a
   coherent allocation? Flag contradictions (e.g. conviction buy on a sector
   while also conviction avoiding a peer in the same sector).

Rules:
  - Do not repeat per-ticker analysis. Only surface cross-asset patterns.
  - If the portfolio is well-diversified, say so clearly — do not manufacture
    concerns.
  - The annotation field should be a concise 2-4 sentence executive summary
    suitable for the top of an investment committee memo.
  - Be specific: name tickers, cite percentages, reference the shared thesis.
"""
def synthesize_portfolio_annotation(
    asset_summaries: str
) -> PortfolioInsight by llm();
