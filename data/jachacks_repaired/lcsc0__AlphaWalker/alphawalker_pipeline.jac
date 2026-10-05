"""Headless Jac pipeline for the FastAPI service — same graph as main.jac, returns JSON."""

import from graph.nodes { PortfolioNode, Asset, VerdictNode, BullNode, BearNode }
import from graph.edges { BelongsToPortfolio, HasVerdict, HasCoalition }
import from agents.bull_coalition_walker { BullCoalitionWalker }
import from agents.bear_coalition_walker { BearCoalitionWalker }
import from agents.judge_agent { JudgeWalker }

def json_str(s: str) -> str {
    t: str = s;
    t = t.replace("\\", "\\\\");
    t = t.replace("\"", "\\\"");
    t = t.replace("\n", "\\n");
    t = t.replace("\r", "\\r");
    t = t.replace("\t", "\\t");
    return "\"" + t + "\"";
}

"""Run bull/bear coalitions + judge per ticker; return a JSON array string for Python to parse."""
def run_pipeline_for_tickers(tickers: list[str], signals_json: str = "{}") -> str {
    import json;
    signals_map = json.loads(signals_json);

    row_strings: list[str] = [];
    portfolio = PortfolioNode(name="AlphaWalker API");
    root ++> portfolio;

    for ticker in tickers {
        asset = Asset(ticker=ticker);
        asset.quant_signals = signals_map.get(ticker, "");
        portfolio +>:BelongsToPortfolio:+> asset;

        asset spawn BullCoalitionWalker(ticker=ticker);
        asset spawn BearCoalitionWalker(ticker=ticker);

        asset spawn JudgeWalker();

        verdicts = [asset ->:HasVerdict:->][?:VerdictNode];
        bull_nodes = [asset ->:HasCoalition:side=="bull":->][?:BullNode];
        bear_nodes = [asset ->:HasCoalition:side=="bear":->][?:BearNode];

        v_verdict: str = "";
        v_jc: int = 0;
        v_rat: str = "";
        v_cond: str = "";
        if len(verdicts) > 0 {
            v = verdicts[0];
            v_verdict = v.verdict;
            v_jc = v.judge_confidence;
            v_rat = v.rationale;
            v_cond = v.condition;
        }

        b_arg: str = "";
        b_conf: int = 0;
        if len(bull_nodes) > 0 {
            b = bull_nodes[0];
            b_arg = b.argument;
            b_conf = b.confidence;
        }

        br_arg: str = "";
        br_conf: int = 0;
        if len(bear_nodes) > 0 {
            br = bear_nodes[0];
            br_arg = br.argument;
            br_conf = br.confidence;
        }

        row = (
            "{"
            + "\"ticker\":" + json_str(ticker)
            + ",\"verdict\":" + json_str(v_verdict)
            + ",\"judge_confidence\":" + str(v_jc)
            + ",\"rationale\":" + json_str(v_rat)
            + ",\"condition\":" + json_str(v_cond)
            + ",\"bull_argument\":" + json_str(b_arg)
            + ",\"bull_confidence\":" + str(b_conf)
            + ",\"bear_argument\":" + json_str(br_arg)
            + ",\"bear_confidence\":" + str(br_conf)
            + "}"
        );
        row_strings.append(row);
    }

    return "[" + ",".join(row_strings) + "]";
}
