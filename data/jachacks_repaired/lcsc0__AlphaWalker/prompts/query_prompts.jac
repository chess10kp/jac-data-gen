"""LLM prompts for the Query Walker."""

obj QueryAnswer {
    has answer: str,
        cited_tickers: list[str],
        confidence_note: str;
}

"""Answer a natural language question about the portfolio using ONLY the
evidence provided in graph_context. Do not use outside knowledge or training
data — if the context does not contain enough information to answer, say so.

graph_context contains structured evidence deposited by AlphaWalker's
coalition agents and judge. It may include:
  - Per-asset bull/bear arguments with sub-agent findings (news, quant, macro)
  - Confidence scores (0-100) per agent and per coalition
  - Momentum trends across prior runs (e.g. weak -> moderate -> strong)
  - Judge verdicts with rationale and conditions
  - Portfolio-level annotations (concentration risk, correlated themes, hedging gaps)

Rules:
  - Ground every claim in specific data from graph_context. Cite ticker names,
    confidence percentages, agent findings, and verdict text.
  - When the question asks about a buy/sell/hold recommendation, reference the
    judge verdict and the coalition arguments that drove it.
  - When the question asks about trends or momentum, reference the temporal
    trajectory (e.g. "bear confidence has risen from weak to strong over three
    runs").
  - If data for a requested ticker or dimension is missing, state what is
    missing rather than guessing.
  - Keep the answer concise: 3-8 sentences in plain English. No jargon, no
    bullet points, no markdown formatting.
  - Populate cited_tickers with every ticker symbol mentioned in your answer.
  - Populate confidence_note with a brief warning if any relevant data was
    missing or if confidence scores were notably low (below 35%). Set to
    empty string if data quality is adequate.
"""
def answer_query(
    question: str,
    graph_context: str
) -> QueryAnswer by llm();
