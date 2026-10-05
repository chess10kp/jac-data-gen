"""Maps the Jac multi-agent graph (`alphawalker_pipeline.jac`) into API `AnalysisResult` models."""

import logging;
import os;

import from api.engine { EngineEvent, RuleBasedAnalysisEngine }
import from api.jac_bridge { run_jac_pipeline }
import from api.models {
    AnalysisRequest,
    AnalysisResult,
    GraphData,
    GraphEdge,
    GraphNode,
    HoldingAnalysis,
    Recommendation
}

glob logger = logging.getLogger("api.jac_engine");

def _risk_band(score: int) -> str {
    if score >= 70 {
        return "high";
    }
    if score >= 45 {
        return "moderate";
    }
    return "low";
}

def _sentiment_summary(scores: list[int]) -> str {
    total: int = 0;
    for s in scores {
        total = total + s;
    }
    if total > 0 {
        return "Positive skew across core holdings";
    }
    if total < 0 {
        return "Mixed to negative across the portfolio";
    }
    return "Mixed";
}

def _has_any(hay: str, needles: list[str]) -> bool {
    for n in needles {
        if n in hay {
            return True;
        }
    }
    return False;
}

def _sentiment_from_row(verdict: str, bull_c: int, bear_c: int) -> str {
    v = (verdict or "").lower();
    if _has_any(v, ["buy", "accumulate", "overweight", "add"]) {
        return "positive";
    }
    if _has_any(v, ["sell", "reduce", "underweight", "trim"]) {
        return "negative";
    }
    if bull_c > bear_c + 15 {
        return "positive";
    }
    if bear_c > bull_c + 15 {
        return "negative";
    }
    return "neutral";
}

def _risk_score(row: dict[str, any], weight: float) -> int {
    jc = int(row.get("judge_confidence", 0) or 0);
    bc = int(row.get("bear_confidence", 0) or 0);
    buc = int(row.get("bull_confidence", 0) or 0);
    base: int = max(10, 100 - min(100, jc));
    diff: int = abs(bc - buc);
    tilt: int = diff // 5;
    concentration: int = min(25, int(weight * 100));
    score: int = base + tilt + (concentration // 2);
    return max(5, min(95, score));
}

def _pct_one(weight: float) -> str {
    v = int(weight * 1000) / 10.0;
    return str(v);
}

def _summary(row: dict[str, any], weight: float, risk: int, sentiment: str) -> str {
    t = str(row.get("ticker", ""));
    rationale_raw = row.get("rationale", "");
    rationale = str(rationale_raw or "").strip();
    verdict_raw = row.get("verdict", "");
    verdict = str(verdict_raw or "").strip();
    pct = _pct_one(weight);
    if rationale != "" {
        clip: str;
        if len(rationale) > 400 {
            clip = rationale[0:397] + "...";
        } else {
            clip = rationale;
        }
        return (
            t + " (" + pct + "% weight): judge verdict «" + verdict + "» ("
            + str(risk) + "/100 risk, " + sentiment + "). " + clip
        );
    }
    vv = verdict;
    if vv == "" {
        vv = "n/a";
    }
    return (
        t + " is " + pct + "% of the portfolio with risk " + str(risk) + "/100 "
        + "and " + sentiment + " tone; verdict: " + vv + "."
    );
}

def _round4(x: float) -> float {
    return int(x * 10000) / 10000.0;
}

def _build_graph(tickers: list[str]) -> GraphData {
    nodes: list[GraphNode] = [];
    edges: list[GraphEdge] = [];
    for ticker in tickers {
        aid = "asset:" + ticker;
        nodes.append(GraphNode(id=aid, label=ticker, kind="asset"));
        nodes.append(GraphNode(id="bull:" + ticker, label=ticker + " bull coalition", kind="bull"));
        nodes.append(GraphNode(id="bear:" + ticker, label=ticker + " bear coalition", kind="bear"));
        nodes.append(GraphNode(id="judge:" + ticker, label=ticker + " judge", kind="judge"));
        edges.append(GraphEdge(source=aid, target="bull:" + ticker, label="coalition"));
        edges.append(GraphEdge(source=aid, target="bear:" + ticker, label="coalition"));
        edges.append(GraphEdge(source="bull:" + ticker, target="judge:" + ticker, label="synthesis"));
        edges.append(GraphEdge(source="bear:" + ticker, target="judge:" + ticker, label="synthesis"));
    }
    return GraphData(nodes=nodes, edges=edges);
}

class JacAnalysisEngine {
    has _fallback: RuleBasedAnalysisEngine;

    def __init__(self: JacAnalysisEngine, fallback: RuleBasedAnalysisEngine | None = None) {
        if fallback is not None {
            self._fallback = fallback;
        } else {
            self._fallback = RuleBasedAnalysisEngine();
        }
    }

    def analyze(self: JacAnalysisEngine, request: AnalysisRequest, emit: any) -> AnalysisResult {
        holdings = request.portfolio.holdings;
        tickers: list[str] = [];
        for h in holdings {
            tickers.append(h.ticker.strip().upper());
        }

        emit(
            EngineEvent(
                agent="portfolio_ingestor",
                stage="started",
                message="Ingested " + str(len(tickers)) + " tickers for Jac graph execution",
                progress=0.08
            )
        );
        emit(
            EngineEvent(
                agent="jac_graph",
                stage="running",
                message="Running bull/bear coalitions and judge walkers (Jac multi-agent engine)",
                progress=0.15
            )
        );

        fb_raw = os.getenv("ALPHAWALKER_JAC_FALLBACK", "1").lower();
        fallback_on_error = fb_raw in ["1", "true", "yes"];

        rows_raw: list[dict[str, any]] = [];
        try {
            rows_raw = run_jac_pipeline(tickers);
        } except Exception as exc {
            logger.warning("Jac pipeline error: %s", str(exc));
            if not fallback_on_error {
                raise exc;
            }
            emit(
                EngineEvent(
                    agent="jac_graph",
                    stage="degraded",
                    message="Jac engine unavailable (" + str(exc) + "); using deterministic fallback",
                    progress=0.2
                )
            );
            return self._fallback.analyze(request, emit);
        }

        by_ticker: dict[str, dict[str, any]] = {};
        for r in rows_raw {
            if isinstance(r, dict) {
                tk = str(r.get("ticker", "")).upper();
                by_ticker[tk] = r;
            }
        }

        holding_results: list[HoldingAnalysis] = [];
        recommendations: list[Recommendation] = [];
        weighted_risk: float = 0.0;
        sentiment_scores: list[int] = [];
        n_hold: int = len(holdings);
        if n_hold < 1 {
            n_hold = 1;
        }

        i: int = 0;
        for holding in holdings {
            i = i + 1;
            t = holding.ticker.strip().upper();
            row: dict[str, any] = {};
            if t in by_ticker {
                row = by_ticker[t];
            }
            sentiment = _sentiment_from_row(
                str(row.get("verdict", "")),
                int(row.get("bull_confidence", 0) or 0),
                int(row.get("bear_confidence", 0) or 0)
            );
            risk = _risk_score(row, holding.weight);
            weighted_risk = weighted_risk + (float(risk) * holding.weight);
            if sentiment == "positive" {
                sentiment_scores.append(1);
            } elif sentiment == "negative" {
                sentiment_scores.append(-1);
            } else {
                sentiment_scores.append(0);
            }

            holding_results.append(
                HoldingAnalysis(
                    ticker=t,
                    weight=_round4(holding.weight),
                    risk_score=risk,
                    sentiment=sentiment,
                    summary=_summary(row, holding.weight, risk, sentiment)
                )
            );

            if request.options.include_rebalancing and (holding.weight >= 0.2 or risk >= 70) {
                tw = holding.weight * 0.75;
                if tw < 0.05 {
                    tw = 0.05;
                }
                recommendations.append(
                    Recommendation(
                        ticker=t,
                        action="reduce",
                        reason="concentration or elevated risk from Jac synthesis",
                        target_weight=_round4(tw)
                    )
                );
            }

            prog: float = 0.2 + 0.55 * float(i) / float(n_hold);
            if prog > 0.75 {
                prog = 0.75;
            }
            emit(
                EngineEvent(
                    agent="risk_analyzer",
                    stage="running",
                    message="Jac synthesis complete for " + t + " (risk " + str(risk) + ")",
                    progress=prog
                )
            );
        }

        overall_risk = int(weighted_risk + 0.5);
        risk_band = _risk_band(overall_risk);
        sentiment_summary = _sentiment_summary(sentiment_scores);

        if request.options.include_rebalancing and len(recommendations) == 0 and len(holding_results) > 0 {
            best = holding_results[0];
            for h in holding_results {
                if h.risk_score < best.risk_score {
                    best = h;
                }
            }
            recommendations.append(
                Recommendation(
                    ticker=best.ticker,
                    action="maintain",
                    reason="Jac graph suggests no mandatory trim vs. current policy",
                    target_weight=_round4(best.weight)
                )
            );
        }

        emit(
            EngineEvent(
                agent="sentiment_agent",
                stage="running",
                message="Aggregated cross-holding sentiment from Jac coalitions",
                progress=0.85
            )
        );
        emit(
            EngineEvent(
                agent="judge_agent",
                stage="completed",
                message="Jac judge walkers finished; portfolio verdict materialized",
                progress=1.0
            )
        );

        out_graph: GraphData = GraphData();
        if request.options.include_graph {
            g_tickers: list[str] = [];
            for h in holdings {
                g_tickers.append(h.ticker.strip().upper());
            }
            out_graph = _build_graph(g_tickers);
        }

        rec_out: list[Recommendation] = [];
        if request.options.include_rebalancing {
            rec_out = recommendations;
        }

        return AnalysisResult(
            overall_risk_score=overall_risk,
            risk_band=risk_band,
            sentiment_summary=sentiment_summary,
            rebalancing_suggestions=rec_out,
            holdings=holding_results,
            graph=out_graph
        );
    }
}
