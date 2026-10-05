"""Query runner — builds graph context from results JSON and answers a natural language question via MTLLM."""

import json;
import from ..prompts.query_prompts { answer_query }

def run_query_for_results(question: str, results_json: str) -> str {
    results = json.loads(results_json);
    lines: list[str] = [];

    for r in results {
        lines.append(f"ASSET: {r['ticker']}");
        lines.append(f"BULL: {r['bull_argument']} | confidence={r['bull_confidence']}%");
        lines.append(f"BEAR: {r['bear_argument']} | confidence={r['bear_confidence']}%");
        lines.append(f"VERDICT: {r['verdict']} | confidence={r['judge_confidence']}%");
        lines.append(f"  Rationale: {r['rationale']}");
        cond = r.get("condition", "");
        if cond and cond.strip() != "" {
            lines.append(f"  Condition: {cond}");
        }
        lines.append("");
    }

    graph_context = "\n".join(lines);
    result = answer_query(question=question, graph_context=graph_context);

    return json.dumps({
        "answer": result.answer,
        "cited_tickers": result.cited_tickers,
        "confidence_note": result.confidence_note
    });
}
