"""Entry point for AlphaWalker CLI — delegates graph execution to `alphawalker_pipeline.jac` (same as FastAPI worker)."""

import json;
import from alphawalker_pipeline { run_pipeline_for_tickers }

with entry:__main__ {
    tickers = ["NVDA", "AAPL", "TSLA"];
    raw = run_pipeline_for_tickers(tickers);
    rows = json.loads(raw);

    for row in rows {
        ticker = str(row.get("ticker", "") or "");
        verdict = str(row.get("verdict", "") or "");
        jc = row.get("judge_confidence", 0);
        if jc is None {
            jc = 0;
        }
        rationale = str(row.get("rationale", "") or "");
        condition = str(row.get("condition", "") or "");

        print(f"\n{'='*60}");
        print(f"  {ticker}");
        print(f"{'='*60}");
        print(f"  Verdict:    {verdict}");
        print(f"  Confidence: {jc}%");
        print(f"  Rationale:  {rationale}");
        if condition != "" {
            print(f"  Condition:  {condition}");
        }
    }

    print(f"\n{'='*60}");
    print("  AlphaWalker run complete.");
    print(f"{'='*60}");
}
