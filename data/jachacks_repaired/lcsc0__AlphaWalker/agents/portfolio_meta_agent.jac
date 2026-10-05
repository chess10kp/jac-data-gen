"""Portfolio Meta Agent — cross-asset reasoning walker."""

import from ..graph.nodes { PortfolioNode, Asset, BullNode, BearNode, VerdictNode, PortfolioAnnotation }
import from ..graph.edges { BelongsToPortfolio, HasCoalition, HasVerdict, HasAnnotation }
import from ..prompts.portfolio_prompts { PortfolioInsight, synthesize_portfolio_annotation }

def build_asset_summaries_text(summaries: list[dict]) -> str {
    lines: list[str] = [];
    for s in summaries {
        line = f"{s['ticker']} | sector={s['sector']} | bull={s['bull_argument']} (conf {s['bull_confidence']}%) | bear={s['bear_argument']} (conf {s['bear_confidence']}%) | verdict={s['verdict']} (conf {s['judge_confidence']}%)";
        lines.append(line);
    }
    return "\n".join(lines);
}

walker PortfolioMetaWalker {
    has asset_summaries: list[dict] = [];

    can enter_portfolio with PortfolioNode entry {
        visit [->:BelongsToPortfolio:->][?:Asset];
    }

    can enter_asset with Asset entry {
        bull_nodes: list[BullNode] = [->:HasCoalition:side=="bull":->][?:BullNode];
        bear_nodes: list[BearNode] = [->:HasCoalition:side=="bear":->][?:BearNode];
        verdict_nodes: list[VerdictNode] = [->:HasVerdict:->][?:VerdictNode];

        ticker: str = here.ticker;
        sector: str = here.sector;
        bull_arg: str = "no data";
        bull_conf: int = 0;
        bear_arg: str = "no data";
        bear_conf: int = 0;
        verd_str: str = "no verdict";
        judge_conf: int = 0;

        if len(bull_nodes) > 0 {
            bull_arg = bull_nodes[0].argument;
            bull_conf = bull_nodes[0].confidence;
        }
        if len(bear_nodes) > 0 {
            bear_arg = bear_nodes[0].argument;
            bear_conf = bear_nodes[0].confidence;
        }
        if len(verdict_nodes) > 0 {
            verd_str = verdict_nodes[0].verdict;
            judge_conf = verdict_nodes[0].judge_confidence;
        }

        summary = {
            "ticker": ticker,
            "sector": sector,
            "bull_argument": bull_arg,
            "bull_confidence": bull_conf,
            "bear_argument": bear_arg,
            "bear_confidence": bear_conf,
            "verdict": verd_str,
            "judge_confidence": judge_conf
        };
        self.asset_summaries.append(summary);
    }

    can exit_portfolio with PortfolioNode exit {
        if len(self.asset_summaries) == 0 {
            report None;
            disengage;
        }

        summaries_text = build_asset_summaries_text(self.asset_summaries);
        result = synthesize_portfolio_annotation(
            asset_summaries=summaries_text
        );

        annotation_node = here +>:HasAnnotation:+> PortfolioAnnotation(
            annotation=result.annotation,
            correlated_theme=result.correlated_theme,
            hedging_gaps=result.hedging_gaps,
            portfolio_conviction=result.portfolio_conviction
        );

        report annotation_node;
    }
}
