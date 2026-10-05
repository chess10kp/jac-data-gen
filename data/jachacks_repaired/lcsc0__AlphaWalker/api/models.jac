"""Core data models for the AlphaWalker analysis service."""

import from datetime { date, datetime, timezone }

def utc_now() -> datetime {
    return datetime.now(timezone.utc);
}

def utc_now_iso() -> str {
    return utc_now().isoformat().replace("+00:00", "Z");
}

def default_as_of_date() -> str {
    d: date = date.today();
    return d.isoformat();
}

obj Holding {
    has ticker: str;
    has weight: float;

    def to_dict -> dict {
        return {"ticker": self.ticker, "weight": self.weight};
    }
}

obj PortfolioInput {
    has holdings: list[Holding];
    has as_of_date: str;

    def to_dict -> dict {
        return {
            "holdings": [h.to_dict() for h in self.holdings],
            "as_of_date": self.as_of_date
        };
    }
}

obj AnalysisOptions {
    has include_sentiment: bool = True;
    has include_rebalancing: bool = True;
    has include_graph: bool = True;

    def to_dict -> dict {
        return {
            "include_sentiment": self.include_sentiment,
            "include_rebalancing": self.include_rebalancing,
            "include_graph": self.include_graph
        };
    }
}

obj ClientContext {
    has source: str = "alphawalker";
    has session_id: str | None = None;

    def to_dict -> dict {
        return {"source": self.source, "session_id": self.session_id};
    }
}

obj AnalysisRequest {
    has portfolio: PortfolioInput;
    has options: AnalysisOptions;
    has client_context: ClientContext;

    def to_dict -> dict {
        return {
            "portfolio": self.portfolio.to_dict(),
            "options": self.options.to_dict(),
            "client_context": self.client_context.to_dict()
        };
    }
}

obj AnalysisError {
    has code: str;
    has message: str;
    has retryable: bool;

    def to_dict -> dict {
        return {
            "code": self.code,
            "message": self.message,
            "retryable": self.retryable
        };
    }
}

obj Recommendation {
    has ticker: str;
    has action: str;
    has reason: str;
    has target_weight: float;

    def to_dict -> dict {
        return {
            "ticker": self.ticker,
            "action": self.action,
            "reason": self.reason,
            "target_weight": self.target_weight
        };
    }
}

obj HoldingAnalysis {
    has ticker: str;
    has weight: float;
    has risk_score: int;
    has sentiment: str;
    has summary: str;

    def to_dict -> dict {
        return {
            "ticker": self.ticker,
            "weight": self.weight,
            "risk_score": self.risk_score,
            "sentiment": self.sentiment,
            "summary": self.summary
        };
    }
}

obj GraphNode {
    has id: str;
    has label: str;
    has kind: str;

    def to_dict -> dict {
        return {"id": self.id, "label": self.label, "kind": self.kind};
    }
}

obj GraphEdge {
    has source: str;
    has target: str;
    has label: str;

    def to_dict -> dict {
        return {"source": self.source, "target": self.target, "label": self.label};
    }
}

obj GraphData {
    has nodes: list[GraphNode] = [];
    has edges: list[GraphEdge] = [];

    def to_dict -> dict {
        return {
            "nodes": [n.to_dict() for n in self.nodes],
            "edges": [e.to_dict() for e in self.edges]
        };
    }
}

obj AnalysisResult {
    has overall_risk_score: int;
    has risk_band: str;
    has sentiment_summary: str;
    has rebalancing_suggestions: list[Recommendation];
    has holdings: list[HoldingAnalysis];
    has graph: GraphData;

    def to_dict -> dict {
        return {
            "overall_risk_score": self.overall_risk_score,
            "risk_band": self.risk_band,
            "sentiment_summary": self.sentiment_summary,
            "rebalancing_suggestions": [
                s.to_dict() for s in self.rebalancing_suggestions
            ],
            "holdings": [h.to_dict() for h in self.holdings],
            "graph": self.graph.to_dict()
        };
    }
}

obj AnalysisEvent {
    has seq: int;
    has timestamp: str;
    has agent: str;
    has stage: str;
    has message: str;

    def to_dict -> dict {
        return {
            "seq": self.seq,
            "timestamp": self.timestamp,
            "agent": self.agent,
            "stage": self.stage,
            "message": self.message
        };
    }
}

obj PortfolioSummary {
    has holdings_count: int;
    has total_weight: float;

    def to_dict -> dict {
        return {
            "holdings_count": self.holdings_count,
            "total_weight": self.total_weight
        };
    }
}

obj RunRecord {
    has run_id: str;
    has status: str;
    has progress: float;
    has portfolio_summary: PortfolioSummary;
    has request_payload: dict[str, any];
    has normalized_holdings: list[dict[str, any]];
    has created_at: str;
    has started_at: str | None = None;
    has finished_at: str | None = None;
    has result: dict | None = None;
    has error: dict | None = None;

    def to_dict -> dict {
        return {
            "run_id": self.run_id,
            "status": self.status,
            "progress": self.progress,
            "portfolio_summary": self.portfolio_summary.to_dict(),
            "created_at": self.created_at,
            "started_at": self.started_at,
            "finished_at": self.finished_at,
            "result": self.result,
            "error": self.error,
            "request_payload": self.request_payload,
            "normalized_holdings": self.normalized_holdings
        };
    }
}
