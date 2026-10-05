"""Bull Coalition Walker — orchestrates the three bull sub-agents."""

import from ..graph.nodes { Asset, BullNode, TemporalSnapshot }
import from ..graph.edges { HasCoalition, HasSnapshot }
import from agents.bull.bull_news_agent { BullNewsAgent }
import from agents.bull.bull_quant_agent { BullQuantAgent }
import from agents.bull.bull_macro_agent { BullMacroAgent }

walker BullCoalitionWalker {
    has ticker: str;
    has run_number: int = 1;

    can enter_asset with Asset entry {
        # Create BullNode and attach to Asset
        bull: BullNode = here +>:HasCoalition(side="bull"):+> BullNode();

        # Spawn three sub-agent walkers on the BullNode
        news_agent = BullNewsAgent(ticker=self.ticker);
        bull spawn news_agent;

        quant_agent = BullQuantAgent(ticker=self.ticker, quant_signals=here.quant_signals);
        bull spawn quant_agent;

        macro_agent = BullMacroAgent(ticker=self.ticker);
        bull spawn macro_agent;

        # Synthesize overall coalition argument and confidence
        bull.argument = (
            f"NEWS: {bull.news_finding} | "
            f"QUANT: {bull.quant_finding} | "
            f"MACRO: {bull.macro_finding}"
        );
        bull.confidence = (
            bull.news_confidence + bull.quant_confidence + bull.macro_confidence
        ) // 3;

        # Create temporal snapshot for momentum tracking
        import datetime;
        bull +>:HasSnapshot:+> TemporalSnapshot(
            timestamp=str(datetime.datetime.now()),
            run_number=self.run_number,
            side="bull",
            argument=bull.argument,
            confidence=bull.confidence,
            news_confidence=bull.news_confidence,
            quant_confidence=bull.quant_confidence,
            macro_confidence=bull.macro_confidence
        );

        report bull;
    }
}
