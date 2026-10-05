"""Query Walker — natural language Q&A over the live graph."""

import from ..graph.nodes {
    PortfolioNode, Asset, BullNode, BearNode,
    TemporalSnapshot, VerdictNode, PortfolioAnnotation
}
import from ..graph.edges {
    BelongsToPortfolio, HasCoalition, HasSnapshot,
    HasVerdict, HasAnnotation
}
import from ..prompts.query_prompts { QueryAnswer, answer_query }

obj AssetContextBlockIn {
    has ticker: str;
    has sector: str;
    has price: float;
    has bull_momentum: str;
    has bear_momentum: str;
    has bull: BullNode | None = None;
    has bear: BearNode | None = None;
    has verdict: VerdictNode | None = None;
}

def confidence_label(score: int) -> str {
    if score >= 70 {
        return "strong";
    } elif score >= 45 {
        return "moderate";
    }
    return "weak";
}

def build_momentum_string(snapshots: list[TemporalSnapshot], depth: int) -> str {
    if len(snapshots) == 0 {
        return "no prior data";
    }
    sorted_snaps: list[TemporalSnapshot] = sorted(
        snapshots,
        key=lambda (s: TemporalSnapshot) { s.run_number; }
    );
    trimmed: list[TemporalSnapshot];
    if len(sorted_snaps) > depth {
        trimmed = sorted_snaps[-depth:];
    } else {
        trimmed = sorted_snaps;
    }
    labels = [confidence_label(s.confidence) for s in trimmed];
    return " -> ".join(labels);
}

def build_asset_context_block(ctx: AssetContextBlockIn) -> str {
    lines: list[str] = [];
    lines.append(f"ASSET: {ctx.ticker} | sector={ctx.sector} | price={ctx.price}");

    if ctx.bull is not None {
        lines.append(f"BULL: {ctx.bull.argument} | confidence={ctx.bull.confidence}%");
        lines.append(f"  News: {ctx.bull.news_finding} ({ctx.bull.news_confidence}%) | Quant: {ctx.bull.quant_finding} ({ctx.bull.quant_confidence}%) | Macro: {ctx.bull.macro_finding} ({ctx.bull.macro_confidence}%)");
        lines.append(f"  Momentum: {ctx.bull_momentum}");
    } else {
        lines.append("BULL: no data");
    }

    if ctx.bear is not None {
        lines.append(f"BEAR: {ctx.bear.argument} | confidence={ctx.bear.confidence}%");
        lines.append(f"  News: {ctx.bear.news_finding} ({ctx.bear.news_confidence}%) | Quant: {ctx.bear.quant_finding} ({ctx.bear.quant_confidence}%) | Macro: {ctx.bear.macro_finding} ({ctx.bear.macro_confidence}%)");
        lines.append(f"  Momentum: {ctx.bear_momentum}");
    } else {
        lines.append("BEAR: no data");
    }

    if ctx.verdict is not None {
        lines.append(f"VERDICT: {ctx.verdict.verdict} | confidence={ctx.verdict.judge_confidence}%");
        lines.append(f"  Rationale: {ctx.verdict.rationale}");
        if ctx.verdict.condition {
            lines.append(f"  Condition: {ctx.verdict.condition}");
        }
    } else {
        lines.append("VERDICT: no verdict");
    }

    return "\n".join(lines);
}

walker QueryWalker {
    has question: str;
    has asset_contexts: list[str] = [];
    has portfolio_context: str = "";
    has snapshot_depth: int = 4;

    can enter_portfolio with PortfolioNode entry {
        # Read portfolio-level annotations if available
        annotations = [->:HasAnnotation:->][?:PortfolioAnnotation];
        if len(annotations) > 0 {
            # Take the most recent annotation by run_number
            sorted_annots = sorted(annotations, key=lambda (a: PortfolioAnnotation) { a.run_number; });
            latest = sorted_annots[-1];
            self.portfolio_context = (
                "PORTFOLIO ANNOTATION:\n"
                + f"  Summary: {latest.annotation}\n"
                + f"  Correlated Theme: {latest.correlated_theme}\n"
                + f"  Hedging Gaps: {latest.hedging_gaps}\n"
                + f"  Portfolio Conviction: {latest.portfolio_conviction}"
            );
        }

        visit [->:BelongsToPortfolio:->][?:Asset];
    }

    can enter_asset with Asset entry {
        bull_nodes = [->:HasCoalition:side=="bull":->][?:BullNode];
        bear_nodes = [->:HasCoalition:side=="bear":->][?:BearNode];
        verdict_nodes = [->:HasVerdict:->][?:VerdictNode];

        bull: BullNode | None = None;
        bear: BearNode | None = None;
        verdict: VerdictNode | None = None;
        bull_momentum: str;
        bear_momentum: str;

        if len(bull_nodes) > 0 {
            bull = bull_nodes[0];
            bull_snapshots = [bull ->:HasSnapshot:->][?:TemporalSnapshot];
            bull_momentum = build_momentum_string(bull_snapshots, self.snapshot_depth);
        } else {
            bull_momentum = "no prior data";
        }
        if len(bear_nodes) > 0 {
            bear = bear_nodes[0];
            bear_snapshots = [bear ->:HasSnapshot:->][?:TemporalSnapshot];
            bear_momentum = build_momentum_string(bear_snapshots, self.snapshot_depth);
        } else {
            bear_momentum = "no prior data";
        }
        if len(verdict_nodes) > 0 {
            verdict = verdict_nodes[0];
        }

        block = build_asset_context_block(
            AssetContextBlockIn(
                ticker=here.ticker,
                sector=here.sector,
                price=here.price,
                bull_momentum=bull_momentum,
                bear_momentum=bear_momentum,
                bull=bull,
                bear=bear,
                verdict=verdict
            )
        );
        self.asset_contexts.append(block);
    }

    can exit_portfolio with PortfolioNode exit {
        if len(self.asset_contexts) == 0 and self.portfolio_context == "" {
            report QueryAnswer(
                answer="No data available in the portfolio to answer this question.",
                cited_tickers=[],
                confidence_note="Portfolio graph is empty — no assets or annotations found."
            );
            disengage;
        }

        # Assemble full graph context
        sections: list[str] = [];
        if self.portfolio_context != "" {
            sections.append(self.portfolio_context);
        }
        for ctx in self.asset_contexts {
            sections.append(ctx);
        }
        full_context = "\n\n".join(sections);

        result = answer_query(
            question=self.question,
            graph_context=full_context
        );

        report result;
    }
}
