"""Application service layer for AlphaWalker analysis runs."""

import logging;
import os;
import threading;
import uuid;
import from concurrent.futures { ThreadPoolExecutor }

import from api.engine { EngineEvent, RuleBasedAnalysisEngine }
import from api.models {
    AnalysisError,
    AnalysisEvent,
    AnalysisRequest,
    ClientContext,
    Holding,
    PortfolioInput,
    PortfolioSummary,
    RunRecord,
    utc_now_iso
}
import from api.storage { RunStorage }

glob logger = logging.getLogger("api.service");

# Canonical string key for a normalized holding list, used for Insforge cache lookups.
def _make_portfolio_key(holdings: list[Holding]) -> str {
    parts: list[str] = [];
    for h in holdings {
        parts.append(f"{h.ticker}:{h.weight:.6f}");
    }
    return ",".join(sorted(parts));
}

def _isclose(a: float, b: float, rel_tol: float, abs_tol: float) -> bool {
    diff: float = abs(a - b);
    if diff <= abs_tol {
        return True;
    }
    scale: float = abs(a);
    if abs(b) > scale {
        scale = abs(b);
    }
    return diff <= rel_tol * scale;
}

def _isclose_zero(a: float, abs_tol: float) -> bool {
    return abs(a) <= abs_tol;
}

def _round6(x: float) -> float {
    return int(x * 1000000.0 + 0.5) / 1000000.0;
}

def _select_engine() -> any {
    use_jac = os.getenv("ALPHAWALKER_USE_JAC", "1").lower() in ["1", "true", "yes"];
    if use_jac {
        try {
            import from api.jac_engine { JacAnalysisEngine }
            return JacAnalysisEngine();
        } except ImportError {
            logger.warning("Jac engine not loaded; using rule-based engine.");
        }
    }
    return RuleBasedAnalysisEngine();
}

obj SubmittedRun {
    has run_id: str;
    has status: str;
    has created_at: str;
}

class AnalysisService {
    has storage: RunStorage;
    has engine: any;
    has insforge: any | None;
    has executor: ThreadPoolExecutor;
    has _run_locks: dict[str, threading.Lock];
    has _insforge_ids: dict[str, str];
    has _insforge_ids_lock: threading.Lock;

    def __init__(self: AnalysisService, storage: RunStorage, engine: any | None = None, insforge: any | None = None) {
        self.storage = storage;
        if engine is not None {
            self.engine = engine;
        } else {
            self.engine = _select_engine();
        }
        self.insforge = insforge;
        self.executor = ThreadPoolExecutor(max_workers=4, thread_name_prefix="alphawalker");
        self._run_locks = {};
        self._insforge_ids = {};
        self._insforge_ids_lock = threading.Lock();
    }

    def shutdown(self: AnalysisService) {
        self.executor.shutdown(`wait=True);
    }

    def recover_incomplete_runs(self: AnalysisService) -> int {
        return self.storage.mark_incomplete_runs_failed(
            AnalysisError(
                code="run_interrupted",
                message="The service restarted before this run completed.",
                retryable=True
            ).to_dict()
        );
    }

    def submit_run(self: AnalysisService, request: AnalysisRequest) -> SubmittedRun {
        (normalized_holdings, normalization_message) = self._normalize_holdings(
            request.portfolio.holdings
        );
        portfolio_key = _make_portfolio_key(normalized_holdings);

        cc: ClientContext;
        if request.client_context is not None {
            cc = request.client_context;
        } else {
            cc = ClientContext();
        }
        normalized_request = AnalysisRequest(
            portfolio=PortfolioInput(
                holdings=normalized_holdings,
                as_of_date=request.portfolio.as_of_date
            ),
            options=request.options,
            client_context=cc
        );
        tw: float = 0.0;
        for h in normalized_holdings {
            tw = tw + h.weight;
        }
        total_weight = _round6(tw);

        # Check Insforge for a recent completed run of the same portfolio (12h cache)
        if self.insforge is not None {
            cached = self.insforge.fetch_recent_portfolio_run(portfolio_key);
            if cached is not None and cached.get("results") {
                logger.info("Portfolio cache hit for key %s", portfolio_key);
                now = utc_now_iso();
                run_id = "run_" + uuid.uuid4().hex[0:12];
                record = RunRecord(
                    run_id=run_id,
                    status="completed",
                    progress=1.0,
                    portfolio_summary=PortfolioSummary(
                        holdings_count=len(normalized_holdings),
                        total_weight=total_weight
                    ),
                    request_payload=normalized_request.to_dict(),
                    normalized_holdings=[h.to_dict() for h in normalized_holdings],
                    created_at=now,
                    started_at=now,
                    finished_at=now,
                    result=cached["results"]
                );
                self.storage.create_run(record);
                return SubmittedRun(run_id=run_id, status="completed", created_at=now);
            }
        }

        created_at = utc_now_iso();
        run_id = "run_" + uuid.uuid4().hex[0:12];

        record = RunRecord(
            run_id=run_id,
            status="queued",
            progress=0.0,
            portfolio_summary=PortfolioSummary(
                holdings_count=len(normalized_holdings),
                total_weight=total_weight
            ),
            request_payload=normalized_request.to_dict(),
            normalized_holdings=[holding.to_dict() for holding in normalized_holdings],
            created_at=created_at
        );
        self.storage.create_run(record);

        if self.insforge is not None {
            tickers = [h.ticker for h in normalized_holdings];
            now_iso = utc_now_iso();
            insforge_row = self.insforge.insert_analysis_run(
                {"tickers": tickers, "status": "queued", "results": {}, "portfolio_key": portfolio_key, "created_at": now_iso}
            );
            if insforge_row is not None and "id" in insforge_row {
                with self._insforge_ids_lock {
                    self._insforge_ids[run_id] = insforge_row["id"];
                }
            }
        }

        if normalization_message is not None and normalization_message != "" {
            self.storage.append_event(
                run_id,
                AnalysisEvent(
                    seq=self.storage.next_seq(run_id),
                    timestamp=utc_now_iso(),
                    agent="portfolio_ingestor",
                    stage="completed",
                    message=normalization_message
                )
            );
        }

        self.executor.submit(self._execute_run, run_id, normalized_request);
        return SubmittedRun(run_id=run_id, status="queued", created_at=created_at);
    }

    def get_run(self: AnalysisService, run_id: str) -> RunRecord | None {
        return self.storage.get_run(run_id);
    }

    def get_events(self: AnalysisService, run_id: str, after_seq: int = 0) -> tuple[list[AnalysisEvent], int] {
        events = self.storage.list_events(run_id, after_seq);
        next_cursor: int;
        if len(events) > 0 {
            next_cursor = events[-1].seq + 1;
        } else {
            next_cursor = after_seq + 1;
        }
        return (events, next_cursor);
    }

    def _execute_run(self: AnalysisService, run_id: str, request: AnalysisRequest) {
        if run_id not in self._run_locks {
            self._run_locks[run_id] = threading.Lock();
        }
        run_lock = self._run_locks[run_id];
        with run_lock {
            self.storage.update_run(
                run_id,
                status="running",
                progress=0.05,
                started_at=utc_now_iso()
            );
            if self.insforge is not None {
                with self._insforge_ids_lock {
                    _ig_id = self._insforge_ids.get(run_id);
                }
                if _ig_id is not None {
                    self.insforge.update_analysis_run(_ig_id, {"status": "running"});
                }
            }
            try {
                def _emit(evt: EngineEvent) {
                    self._emit_event(run_id, evt);
                }
                result = self.engine.analyze(request, _emit);
                result_dict = result.to_dict();
                self.storage.update_run(
                    run_id,
                    status="completed",
                    progress=1.0,
                    finished_at=utc_now_iso(),
                    result=result_dict
                );
                if self.insforge is not None {
                    with self._insforge_ids_lock {
                        insforge_id = self._insforge_ids.pop(run_id, None);
                    }
                    if insforge_id is not None {
                        self.insforge.update_analysis_run(
                            insforge_id,
                            {"status": "completed", "results": result_dict}
                        );
                        # The rule-based engine returns holdings with sentiment/risk_score/summary.
                        # Bull/bear fields are only available from the Jac pipeline (/v1/analyze-tickers),
                        # so defaults are used here. Task 4 handles the richer mapping.
                        verdicts = [];
                        for h in result_dict.get("holdings", []) {
                            verdicts.append({
                                "run_id": insforge_id,
                                "ticker": h.get("ticker", ""),
                                "verdict": h.get("sentiment", ""),
                                "judge_confidence": h.get("risk_score", 0),
                                "rationale": h.get("summary", ""),
                                "bull_confidence": 0,
                                "bear_confidence": 0,
                                "bull_argument": "",
                                "bear_argument": "",
                                "condition": ""
                            });
                        }
                        self.insforge.insert_ticker_verdicts(verdicts);
                    }
                }
            } except Exception as exc {
                error = AnalysisError(
                    code="analysis_failed",
                    message=str(exc),
                    retryable=False
                ).to_dict();
                self._emit_event(
                    run_id,
                    EngineEvent(
                        agent="judge_agent",
                        stage="failed",
                        message="The analysis run failed before producing a result",
                        progress=0.99
                    )
                );
                self.storage.update_run(
                    run_id,
                    status="failed",
                    progress=0.99,
                    finished_at=utc_now_iso(),
                    error=error
                );
                if self.insforge is not None {
                    with self._insforge_ids_lock {
                        insforge_id = self._insforge_ids.pop(run_id, None);
                    }
                    if insforge_id is not None {
                        self.insforge.update_analysis_run(
                            insforge_id,
                            {"status": "failed"}
                        );
                    }
                }
            }
        }
    }

    def _emit_event(self: AnalysisService, run_id: str, event: EngineEvent) {
        seq = self.storage.next_seq(run_id);
        self.storage.append_event(
            run_id,
            AnalysisEvent(
                seq=seq,
                timestamp=utc_now_iso(),
                agent=event.agent,
                stage=event.stage,
                message=event.message
            )
        );
        if event.progress is not None {
            p: float = event.progress;
            if p < 0.0 {
                p = 0.0;
            }
            if p > 1.0 {
                p = 1.0;
            }
            self.storage.update_run(run_id, progress=p);
        }
    }

    def _normalize_holdings(
        self: AnalysisService, holdings: list[Holding]
    ) -> tuple[list[Holding], str | None] {
        merged: dict[str, float] = {};
        original_count: int = 0;
        for holding in holdings {
            ticker = holding.ticker.strip().upper();
            if ticker == "" {
                continue;
            }
            original_count = original_count + 1;
            if holding.weight < 0 {
                raise ValueError("Negative weight is not allowed for " + ticker + ".");
            }
            prev: float = 0.0;
            if ticker in merged {
                prev = merged[ticker];
            }
            merged[ticker] = prev + holding.weight;
        }

        keys_sorted = sorted(merged.keys());
        normalized: list[Holding] = [];
        for ticker in keys_sorted {
            normalized.append(Holding(ticker=ticker, weight=merged[ticker]));
        }

        if len(normalized) == 0 {
            raise ValueError("Portfolio must contain at least one holding.");
        }

        total_weight: float = 0.0;
        for h in normalized {
            total_weight = total_weight + h.weight;
        }

        if _isclose(total_weight, 1.0, 1e-6, 1e-6) {
            if len(normalized) != original_count {
                return (
                    normalized,
                    "Merged duplicate tickers into " + str(len(normalized)) + " normalized holdings."
                );
            }
            return (normalized, None);
        }

        if _isclose_zero(total_weight, 1e-9) {
            raise ValueError("Portfolio weights must sum to more than zero.");
        }

        rebuilt: list[Holding] = [];
        for h in normalized {
            nw = _round6(h.weight / total_weight);
            rebuilt.append(Holding(ticker=h.ticker, weight=nw));
        }
        normalized = rebuilt;

        correction_kind: str;
        if len(normalized) != original_count {
            correction_kind = "Merged duplicate tickers and normalized weights";
        } else {
            correction_kind = "Normalized weights";
        }
        return (
            normalized,
            correction_kind + " to total 1.0 across " + str(len(normalized)) + " holdings."
        );
    }
}
