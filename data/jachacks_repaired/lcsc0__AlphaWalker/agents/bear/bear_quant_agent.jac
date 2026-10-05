# agents/bear/bear_quant_agent.jac
# Walker: Bear Quant Agent
# Directive: Flag valuation excess, deteriorating margins, earnings misses, broken
# technicals — overextended RSI, failed breakouts, declining EPS revisions.
# Deposits findings + confidence score (0-100) onto BearNode before disengaging.
"""Bear Quant Agent — flags valuation excess and bearish technicals."""

import from ....graph.nodes { BearNode }
import from ....prompts.bear_prompts { analyze_bear_quant }

walker BearQuantAgent {
    has ticker: str;
    has quant_signals: str = "";

    can analyze with BearNode entry {
        result = analyze_bear_quant(ticker=self.ticker, quant_signals=self.quant_signals);
        here.quant_finding = result.findings;
        here.quant_confidence = result.confidence;
        report result;
        disengage;
    }
}
