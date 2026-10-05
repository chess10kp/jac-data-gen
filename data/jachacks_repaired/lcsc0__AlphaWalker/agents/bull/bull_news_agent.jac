"""Bull News Agent — scans for positive news catalysts."""

import from ....graph.nodes { BullNode }
import from ....prompts.bull_prompts { analyze_bull_news }

walker BullNewsAgent {
    has ticker: str;

    can analyze with BullNode entry {
        result = analyze_bull_news(ticker=self.ticker);
        here.news_finding = result.findings;
        here.news_confidence = result.confidence;
        report result;
        disengage;
    }
}
