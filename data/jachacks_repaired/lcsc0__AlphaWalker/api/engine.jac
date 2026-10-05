"""Analysis engines for AlphaWalker."""


import from api.models {
    AnalysisRequest,
    AnalysisResult,
    GraphData,
    GraphEdge,
    GraphNode,
    HoldingAnalysis,
    Recommendation
}

obj EngineEvent {
    has agent: str;
    has stage: str;
    has message: str;
    has progress: float | None = None;
}

class RuleBasedAnalysisEngine {
    def analyze(self: RuleBasedAnalysisEngine, request: AnalysisRequest, emit: any) -> AnalysisResult {
        positive = {"NVDA", "MSFT", "AAPL", "AMZN", "META", "GOOGL"};
        negative = {"TSLA", "SMCI", "COIN", "MSTR", "PLTR"};
        holdings = request.portfolio.holdings;

        emit(
            EngineEvent(
                agent="portfolio_ingestor",
                stage="started",
                message="Normalized " + str(len(holdings)) + " holdings for analysis",
                progress=0.1
            )
        );
        emit(
            EngineEvent(
                agent="researcher",
                stage="running",
                message="Scanning the portfolio for concentration and crowding risk",
                progress=0.25
            )
        );

        holding_results: list[HoldingAnalysis] = [];
        recommendations: list[Recommendation] = [];
        graph_nodes: list[GraphNode] = [];
        graph_edges: list[GraphEdge] = [];

        weighted_risk_total: float = 0.0;
        sentiment_scores: list[int] = [];

        index: int = 0;
        for holding in holdings {
            index = index + 1;
            ticker = holding.ticker.upper();
            concentration_penalty: int = min(int(holding.weight * 100), 35);
            ord_sum: int = 0;
            for ch in ticker {
                oc: int = ord(ch);
                ord_sum = ord_sum + oc;
            }
            base_risk: int = 35 + concentration_penalty + ((ord_sum % 17) * 2);

            sentiment = "neutral";
            sentiment_score: int = 0;
            if ticker in positive {
                base_risk = base_risk - 8;
                sentiment = "positive";
                sentiment_score = 1;
            } elif ticker in negative {
                base_risk = base_risk + 10;
                sentiment = "negative";
                sentiment_score = -1;
            }

            risk_score: int = max(5, min(base_risk, 95));
            weighted_risk_total = weighted_risk_total + (float(risk_score) * holding.weight);
            sentiment_scores.append(sentiment_score);

            summary = self._build_summary(
                ticker=ticker,
                weight=holding.weight,
                risk_score=risk_score,
                sentiment=sentiment
            );
            w_rounded = int(holding.weight * 10000) / 10000.0;
            holding_results.append(
                HoldingAnalysis(
                    ticker=ticker,
                    weight=w_rounded,
                    risk_score=risk_score,
                    sentiment=sentiment,
                    summary=summary
                )
            );

            if holding.weight >= 0.2 or risk_score >= 70 {
                tw = max(holding.weight * 0.7, 0.05);
                target_weight = int(tw * 10000) / 10000.0;
                recommendations.append(
                    Recommendation(
                        ticker=ticker,
                        action="reduce",
                        reason="position concentration and volatility",
                        target_weight=target_weight
                    )
                );
            }

            if request.options.include_graph {
                asset_id = "asset:" + ticker;
                graph_nodes.extend(
                    [
                        GraphNode(id=asset_id, label=ticker, kind="asset"),
                        GraphNode(id="bull:" + ticker, label=ticker + " Bull", kind="bull"),
                        GraphNode(id="bear:" + ticker, label=ticker + " Bear", kind="bear"),
                        GraphNode(id="judge:" + ticker, label=ticker + " Judge", kind="judge")
                    ]
                );
                graph_edges.extend(
                    [
                        GraphEdge(source=asset_id, target="bull:" + ticker, label="analyzed_by"),
                        GraphEdge(source=asset_id, target="bear:" + ticker, label="analyzed_by"),
                        GraphEdge(source="bull:" + ticker, target="judge:" + ticker, label="debated"),
                        GraphEdge(source="bear:" + ticker, target="judge:" + ticker, label="debated")
                    ]
                );
            }

            denom: int = len(holdings);
            if denom < 1 {
                denom = 1;
            }
            prog: float = 0.25 + (0.4 * float(index) / float(denom));
            if prog > 0.65 {
                prog = 0.65;
            }
            emit(
                EngineEvent(
                    agent="risk_analyzer",
                    stage="running",
                    message="Evaluated " + ticker + " with risk score " + str(risk_score),
                    progress=prog
                )
            );
        }

        emit(
            EngineEvent(
                agent="sentiment_agent",
                stage="running",
                message="Synthesizing cross-holding sentiment and allocation pressure",
                progress=0.8
            )
        );

        overall_risk_score = int(round(weighted_risk_total));
        risk_band = self._risk_band(overall_risk_score);
        sentiment_summary = self._sentiment_summary(sentiment_scores);

        if request.options.include_rebalancing and len(recommendations) == 0 and len(holding_results) > 0 {
            lowest = holding_results[0];
            for h in holding_results {
                if h.risk_score < lowest.risk_score {
                    lowest = h;
                }
            }
            tw_m = int(lowest.weight * 10000) / 10000.0;
            recommendations.append(
                Recommendation(
                    ticker=lowest.ticker,
                    action="maintain",
                    reason="portfolio looks balanced relative to current signals",
                    target_weight=tw_m
                )
            );
        }

        emit(
            EngineEvent(
                agent="judge_agent",
                stage="completed",
                message="Finished portfolio verdict and rebalancing recommendations",
                progress=1.0
            )
        );

        graph = GraphData();
        if request.options.include_graph {
            graph = GraphData(nodes=graph_nodes, edges=graph_edges);
        }

        return AnalysisResult(
            overall_risk_score=overall_risk_score,
            risk_band=risk_band,
            sentiment_summary=sentiment_summary,
            rebalancing_suggestions=recommendations
                if request.options.include_rebalancing
                else [],
            holdings=holding_results,
            graph=graph
        );
    }

    def _build_summary(
        self: RuleBasedAnalysisEngine,
        ticker: str,
        weight: float,
        risk_score: int,
        sentiment: str
    ) -> str {
        if sentiment == "positive" {
            tone = "favorable momentum with manageable downside";
        } elif sentiment == "negative" {
            tone = "elevated downside sensitivity and headline risk";
        } else {
            tone = "mixed signals with no decisive catalyst";
        }
        pct = int(weight * 1000) / 10.0;
        return (
            ticker + " is " + str(pct) + "% of the portfolio with a "
            + str(risk_score) + "/100 risk score, suggesting " + tone + "."
        );
    }

    def _risk_band(self: RuleBasedAnalysisEngine, score: int) -> str {
        if score >= 70 {
            return "high";
        }
        if score >= 45 {
            return "moderate";
        }
        return "low";
    }

    def _sentiment_summary(self: RuleBasedAnalysisEngine, scores: list[int]) -> str {
        score: int = 0;
        for s in scores {
            score = score + s;
        }
        if score > 0 {
            return "Positive skew across core holdings";
        }
        if score < 0 {
            return "Mixed to negative across the portfolio";
        }
        return "Mixed";
    }
}
