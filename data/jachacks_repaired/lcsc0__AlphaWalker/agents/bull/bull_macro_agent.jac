"""Bull Macro Agent — identifies favorable macroeconomic tailwinds."""

import from ....graph.nodes { BullNode }
import from ....prompts.bull_prompts { analyze_bull_macro }

walker BullMacroAgent {
    has ticker: str;

    can analyze with BullNode entry {
        result = analyze_bull_macro(ticker=self.ticker);
        here.macro_finding = result.findings;
        here.macro_confidence = result.confidence;
        report result;
        disengage;
    }
}
