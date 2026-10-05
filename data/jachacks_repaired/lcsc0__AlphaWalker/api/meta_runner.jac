"""Meta agent runner — builds asset summaries from results JSON and calls synthesize_portfolio_annotation via MTLLM."""

import json;
import from ..prompts.portfolio_prompts { synthesize_portfolio_annotation }

def run_meta_for_results(results_json: str) -> str {
    results = json.loads(results_json);
    lines: list[str] = [];

    for r in results {
        ticker = r.get("ticker", "");
        sector = r.get("sector", "");
        bull_arg = r.get("bull_argument", "no data");
        bull_conf = r.get("bull_confidence", 0);
        bear_arg = r.get("bear_argument", "no data");
        bear_conf = r.get("bear_confidence", 0);
        verdict = r.get("verdict", "no verdict");
        judge_conf = r.get("judge_confidence", 0);

        line = f"{ticker} | sector={sector} | bull={bull_arg} (conf {bull_conf}%) | bear={bear_arg} (conf {bear_conf}%) | verdict={verdict} (conf {judge_conf}%)";
        lines.append(line);
    }

    asset_summaries = "\n".join(lines);
    result = synthesize_portfolio_annotation(asset_summaries=asset_summaries);

    return json.dumps({
        "annotation": result.annotation,
        "correlated_theme": result.correlated_theme,
        "hedging_gaps": result.hedging_gaps,
        "portfolio_conviction": result.portfolio_conviction
    });
}
