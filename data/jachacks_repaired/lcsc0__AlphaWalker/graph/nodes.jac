"""Graph node definitions for AlphaWalker."""

node PortfolioNode {
    has name: str = "default";
}

node Asset {
    has ticker: str,
        price: float = 0.0,
        sector: str = "",
        quant_signals: str = "";
}

node BullNode {
    has argument: str = "",
        confidence: int = 0,
        news_finding: str = "",
        news_confidence: int = 0,
        quant_finding: str = "",
        quant_confidence: int = 0,
        macro_finding: str = "",
        macro_confidence: int = 0;
}

node BearNode {
    has argument: str = "",
        confidence: int = 0,
        news_finding: str = "",
        news_confidence: int = 0,
        quant_finding: str = "",
        quant_confidence: int = 0,
        macro_finding: str = "",
        macro_confidence: int = 0;
}

node TemporalSnapshot {
    has timestamp: str = "",
        run_number: int = 0,
        side: str = "",
        argument: str = "",
        confidence: int = 0,
        news_confidence: int = 0,
        quant_confidence: int = 0,
        macro_confidence: int = 0;
}

node VerdictNode {
    has verdict: str = "",
        judge_confidence: int = 0,
        rationale: str = "",
        condition: str = "";
}

node PortfolioAnnotation {
    has annotation: str = "",
        correlated_theme: str = "",
        hedging_gaps: str = "",
        portfolio_conviction: str = "",
        timestamp: str = "",
        run_number: int = 0;
}

node RebalanceNode {
    has timestamp: str = "",
        gap_summary: str = "",
        picks: list[dict] = [];
}
