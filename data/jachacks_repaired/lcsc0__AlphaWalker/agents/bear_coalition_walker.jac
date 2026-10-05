"""Bear Coalition Walker — orchestrates the three bear sub-agents."""

import from ..graph.nodes { Asset, BearNode, TemporalSnapshot }
import from ..graph.edges { HasCoalition, HasSnapshot }
import from agents.bear.bear_news_agent { BearNewsAgent }
import from agents.bear.bear_quant_agent { BearQuantAgent }
import from agents.bear.bear_macro_agent { BearMacroAgent }

walker BearCoalitionWalker {
    has ticker: str;
    has run_number: int = 1;

    can enter_asset with Asset entry {
        # Create BearNode and attach to Asset
        bear: BearNode = here +>:HasCoalition(side="bear"):+> BearNode();

        # Spawn three sub-agent walkers on the BearNode
        news_agent = BearNewsAgent(ticker=self.ticker);
        bear spawn news_agent;

        quant_agent = BearQuantAgent(ticker=self.ticker, quant_signals=here.quant_signals);
        bear spawn quant_agent;

        macro_agent = BearMacroAgent(ticker=self.ticker);
        bear spawn macro_agent;

        # Synthesize overall coalition argument and confidence
        bear.argument = (
            f"NEWS: {bear.news_finding} | "
            f"QUANT: {bear.quant_finding} | "
            f"MACRO: {bear.macro_finding}"
        );
        bear.confidence = (
            bear.news_confidence + bear.quant_confidence + bear.macro_confidence
        ) // 3;

        # Create temporal snapshot for momentum tracking
        import datetime;
        bear +>:HasSnapshot:+> TemporalSnapshot(
            timestamp=str(datetime.datetime.now()),
            run_number=self.run_number,
            side="bear",
            argument=bear.argument,
            confidence=bear.confidence,
            news_confidence=bear.news_confidence,
            quant_confidence=bear.quant_confidence,
            macro_confidence=bear.macro_confidence
        );

        report bear;
    }
}
