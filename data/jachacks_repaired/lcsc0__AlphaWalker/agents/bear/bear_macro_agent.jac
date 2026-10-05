"""Bear Macro Agent — identifies macroeconomic headwinds."""

import from ....graph.nodes { BearNode }
import from ....prompts.bear_prompts { analyze_bear_macro }

walker BearMacroAgent {
    has ticker: str;

    can analyze with BearNode entry {
        result = analyze_bear_macro(ticker=self.ticker);
        here.macro_finding = result.findings;
        here.macro_confidence = result.confidence;
        report result;
        disengage;
    }
}
