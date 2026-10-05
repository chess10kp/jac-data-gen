"""FastAPI application exposing AlphaWalker analysis runs.

Analysis executes the Jac multi-agent graph (`alphawalker_pipeline.jac`) by default,
with SQLite-backed run state for polling. See `DEPLOYMENT.md` for env vars.
"""

import os;
import from datetime { datetime, timezone }
import from pathlib { Path }
import from fastapi { Depends, FastAPI, Header, HTTPException, Query }
import from fastapi.middleware.cors { CORSMiddleware }
import from pydantic { BaseModel }

import from api.models {
    AnalysisOptions,
    AnalysisRequest,
    ClientContext,
    Holding,
    PortfolioInput
}
import from api.jac_bridge { run_jac_pipeline }
import from api.meta_bridge { run_meta }
import from api.prices { fetch_historical_prices }
import from api.query_bridge { run_query }
import from api.rebalance_bridge { run_rebalance }
import from api.service { AnalysisService }
import from api.storage { RunStorage }
import from api.insforge_client { create_insforge_client }
import from api.verdict_cache { get as cache_get, set_verdict as cache_set }

class HoldingIn(BaseModel) {
    has ticker: str;
    has weight: float;
}

class PortfolioInputIn(BaseModel) {
    has holdings: list[HoldingIn];
    has as_of_date: str;
}

class AnalysisOptionsIn(BaseModel) {
    has include_sentiment: bool = True;
    has include_rebalancing: bool = True;
    has include_graph: bool = True;
}

class ClientContextIn(BaseModel) {
    has source: str = "alphawalker";
    has session_id: str | None = None;
}

class AnalysisRequestIn(BaseModel) {
    has portfolio: PortfolioInputIn;
    has options: AnalysisOptionsIn = AnalysisOptionsIn();
    has client_context: ClientContextIn = ClientContextIn();
}

class AnalyzeTickersIn(BaseModel) {
    has tickers: list[str];
}

class QueryIn(BaseModel) {
    has question: str;
    has results: list[dict];
}

class PortfolioAnnotationIn(BaseModel) {
    has annotation: str = "";
    has correlated_theme: str = "";
    has hedging_gaps: str = "";
    has portfolio_conviction: str = "";
}

class RebalanceIn(BaseModel) {
    has tickers: list[str];
    has portfolio_annotation: PortfolioAnnotationIn;
    has results: list[dict] = [];
}

glob APP_ROOT = Path(__file__).resolve().parent.parent;
glob DB_PATH = os.getenv("ALPHAWALKER_DB_PATH", str(APP_ROOT / "data" / "analysis_runs.db"));
glob API_KEY = os.getenv("ALPHAWALKER_API_KEY", "");
glob storage = RunStorage(DB_PATH);
glob insforge_client = create_insforge_client(
    os.getenv("INSFORGE_URL"),
    os.getenv("INSFORGE_SERVICE_KEY")
);
glob service = AnalysisService(storage, insforge=insforge_client);
glob startup_recover_count = service.recover_incomplete_runs();
glob app = FastAPI(title="AlphaWalker API", version="0.1.0");

with entry {
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["http://localhost:3000", "http://localhost:5173", "http://127.0.0.1:3000", "http://127.0.0.1:5173"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"]
    );
}

def require_api_key(x_api_key: Annotated[str | None, Header()] = None) {
    if API_KEY == "" {
        return;
    }
    if x_api_key != API_KEY {
        raise HTTPException(status_code=401, detail="Unauthorized");
    }
}

def _normalize_ticker_list(raw: list[str]) -> list[str] {
    out: list[str] = [];
    for t in raw {
        if t and t.strip() != "" {
            out.append(t.strip().upper());
        }
    }
    return out;
}

def _int_field(v: int | str | None) -> int {
    if v is None {
        return 0;
    }
    return int(v);
}

def _row_with_confidence(r: dict) -> dict {
    jc_i = _int_field(r.get("judge_confidence", 0));
    return {
        "ticker": str(r.get("ticker", "") or ""),
        "verdict": str(r.get("verdict", "") or ""),
        "confidence": jc_i,
        "rationale": str(r.get("rationale", "") or ""),
        "condition": str(r.get("condition", "") or ""),
        "judge_confidence": jc_i,
        "bull_argument": str(r.get("bull_argument", "") or ""),
        "bull_confidence": _int_field(r.get("bull_confidence", 0)),
        "bear_argument": str(r.get("bear_argument", "") or ""),
        "bear_confidence": _int_field(r.get("bear_confidence", 0))
    };
}

def _analyze_tickers_response(body: AnalyzeTickersIn) -> dict {
    tickers = _normalize_ticker_list(body.tickers);
    if len(tickers) == 0 {
        raise HTTPException(
            status_code=400,
            detail="Provide at least one non-empty ticker."
        );
    }

    # Check cache — skip pipeline for tickers analyzed within the last 12 hours.
    # Prefer Insforge (persists across restarts); fall back to in-memory cache.
    cached: dict = {};
    if insforge_client is not None {
        for (ticker, row) in insforge_client.fetch_recent_verdicts(tickers).items() {
            cached[ticker] = _row_with_confidence(row);
        }
    }
    for t in tickers {
        if t not in cached {
            hit = cache_get(t);
            if hit is not None {
                cached[t] = hit;
            }
        }
    }
    fresh_tickers = [t for t in tickers if t not in cached];

    rows_raw: list[dict] = [];
    if len(fresh_tickers) > 0 {
        try {
            rows_raw = run_jac_pipeline(fresh_tickers);
        } except Exception as exc {
            raise HTTPException(status_code=502, detail=str(exc));
        }
    }

    # Merge: fresh results + cached, preserving original ticker order
    fresh_map: dict = {};
    for r in rows_raw {
        if isinstance(r, dict) and r.get("ticker") {
            row = _row_with_confidence(r);
            fresh_map[r["ticker"]] = row;
            cache_set(r["ticker"], row);  # store in 12h TTL cache
        }
    }
    data: list[dict] = [];
    for t in tickers {
        if t in fresh_map {
            data.append(fresh_map[t]);
        } elif t in cached {
            data.append(cached[t]);
        }
    }
    portfolio_meta: dict | None = None;
    try {
        portfolio_meta = run_meta(data);
    } except Exception as meta_exc {
        import logging;
        logging.getLogger("api.main").warning("Meta agent failed (non-fatal): %s", meta_exc);
    }

    # Only persist fresh results — cached verdicts are already in the DB
    if insforge_client is not None and len(fresh_tickers) > 0 {
        fresh_data = [d for d in data if d.get("ticker", "") in fresh_map];
        if len(fresh_data) > 0 {
            now_iso = datetime.now(timezone.utc).isoformat();
            insforge_row = insforge_client.insert_analysis_run({
                "tickers": tickers,
                "status": "completed",
                "results": data,
                "created_at": now_iso
            });
            if insforge_row is not None and "id" in insforge_row {
                insforge_run_id = insforge_row["id"];
                verdicts: list[dict] = [];
                for d in fresh_data {
                    verdicts.append({
                        "run_id": insforge_run_id,
                        "ticker": d.get("ticker", ""),
                        "verdict": d.get("verdict", ""),
                        "judge_confidence": d.get("judge_confidence", 0),
                        "bull_confidence": d.get("bull_confidence", 0),
                        "bear_confidence": d.get("bear_confidence", 0),
                        "rationale": d.get("rationale", ""),
                        "condition": d.get("condition", ""),
                        "bull_argument": d.get("bull_argument", ""),
                        "bear_argument": d.get("bear_argument", ""),
                        "created_at": now_iso
                    });
                }
                if len(verdicts) > 0 {
                    insforge_client.insert_ticker_verdicts(verdicts);
                }
            }
        }
    }
    return {"status": "success", "data": data, "portfolio_meta": portfolio_meta};
}

def to_request(payload: AnalysisRequestIn) -> AnalysisRequest {
    hs: list[Holding] = [];
    for item in payload.portfolio.holdings {
        hs.append(Holding(ticker=item.ticker, weight=item.weight));
    }
    return AnalysisRequest(
        portfolio=PortfolioInput(holdings=hs, as_of_date=payload.portfolio.as_of_date),
        options=AnalysisOptions(
            include_sentiment=payload.options.include_sentiment,
            include_rebalancing=payload.options.include_rebalancing,
            include_graph=payload.options.include_graph
        ),
        client_context=ClientContext(
            source=payload.client_context.source,
            session_id=payload.client_context.session_id
        )
    );
}

@app.get("/health")
def health() -> dict[str, str] {
    return {"status": "ok"};
}

@app.post("/v1/analyze-tickers", dependencies=[Depends(require_api_key)])
def analyze_tickers_v1(body: AnalyzeTickersIn) -> dict {
    return _analyze_tickers_response(body);
}

@app.post("/analyze", dependencies=[Depends(require_api_key)])
def analyze_tickers_alias(body: AnalyzeTickersIn) -> dict {
    return _analyze_tickers_response(body);
}

@app.post("/v1/analysis-runs", dependencies=[Depends(require_api_key)])
def create_analysis_run(payload: AnalysisRequestIn) -> dict[str, str] {
    for item in payload.portfolio.holdings {
        if item.ticker.strip() == "" {
            raise ValueError("Each holding must include a non-empty ticker.");
        }
        if item.weight <= 0 {
            raise ValueError("Holding weights must be greater than zero.");
        }
    }
    try {
        run = service.submit_run(to_request(payload));
    } except ValueError as exc {
        raise HTTPException(status_code=400, detail=str(exc));
    }
    return {
        "run_id": run.run_id,
        "status": run.status,
        "created_at": run.created_at
    };
}

@app.get("/v1/analysis-runs/{run_id}", dependencies=[Depends(require_api_key)])
def get_analysis_run(run_id: str) -> dict {
    run = service.get_run(run_id);
    if run is None {
        raise HTTPException(status_code=404, detail="Run not found");
    }
    return {
        "run_id": run.run_id,
        "status": run.status,
        "progress": run.progress,
        "portfolio_summary": run.portfolio_summary.to_dict(),
        "result": run.result,
        "error": run.error,
        "started_at": run.started_at,
        "finished_at": run.finished_at
    };
}

@app.get("/v1/analysis-runs/{run_id}/events", dependencies=[Depends(require_api_key)])
def get_analysis_events(
    run_id: str,
    cursor: Annotated[int, Query(ge=0)] = 0
) -> dict {
    run = service.get_run(run_id);
    if run is None {
        raise HTTPException(status_code=404, detail="Run not found");
    }
    after: int = int(cursor);
    (events, next_cursor) = service.get_events(run_id, after);
    return {
        "run_id": run_id,
        "events": [event.to_dict() for event in events],
        "next_cursor": next_cursor
    };
}

@app.post("/v1/query", dependencies=[Depends(require_api_key)])
def query_portfolio(body: QueryIn) -> dict {
    if not body.question or body.question.strip() == "" {
        raise HTTPException(status_code=400, detail="question must be a non-empty string.");
    }
    if not body.results or len(body.results) == 0 {
        raise HTTPException(status_code=400, detail="results must be a non-empty list.");
    }
    try {
        answer = run_query(body.question.strip(), body.results);
    } except Exception as exc {
        raise HTTPException(status_code=502, detail=str(exc));
    }
    return {"status": "success", "data": answer};
}

@app.post("/v1/rebalance", dependencies=[Depends(require_api_key)])
def rebalance_portfolio(body: RebalanceIn) -> dict {
    tickers = _normalize_ticker_list(body.tickers);
    if len(tickers) == 0 {
        raise HTTPException(status_code=400, detail="Provide at least one non-empty ticker.");
    }
    annotation = {
        "correlated_theme": body.portfolio_annotation.correlated_theme,
        "hedging_gaps": body.portfolio_annotation.hedging_gaps,
        "portfolio_conviction": body.portfolio_annotation.portfolio_conviction
    };
    try {
        result = run_rebalance(tickers, annotation, body.results);
    } except Exception as exc {
        raise HTTPException(status_code=502, detail=str(exc));
    }
    if result is None {
        raise HTTPException(status_code=502, detail="Rebalance agent failed to produce a result.");
    }
    return {"status": "success", "data": result};
}

@app.get("/v1/historical-prices/{ticker}", dependencies=[Depends(require_api_key)])
def get_historical_prices(ticker: str, period: str = "1y") -> dict {
    allowed = ["1mo", "3mo", "6mo", "1y", "2y", "5y"];
    if period not in allowed {
        raise HTTPException(status_code=400, detail=f"period must be one of {allowed}");
    }
    try {
        prices = fetch_historical_prices(ticker, period);
    } except Exception as exc {
        raise HTTPException(status_code=502, detail=str(exc));
    }
    return {"ticker": ticker.upper(), "prices": prices};
}
