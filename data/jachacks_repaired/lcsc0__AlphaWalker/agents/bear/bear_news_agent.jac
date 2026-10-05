"""Bear News Agent — surfaces negative headlines and risk catalysts."""

import from ....graph.nodes { BearNode }
import from ....prompts.bear_prompts { analyze_bear_news }

walker BearNewsAgent {
    has ticker: str;

    can analyze with BearNode entry {
        result = analyze_bear_news(ticker=self.ticker);
        here.news_finding = result.findings;
        here.news_confidence = result.confidence;
        report result;
        disengage;
    }
}
