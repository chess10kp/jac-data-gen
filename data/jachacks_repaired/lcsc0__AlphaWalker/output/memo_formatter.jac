"""Investment committee memo formatter."""

import from ..graph.nodes {
    PortfolioNode, Asset, BullNode, BearNode,
    TemporalSnapshot, VerdictNode, PortfolioAnnotation
}
import from ..graph.edges {
    BelongsToPortfolio, HasCoalition, HasSnapshot,
    HasVerdict, HasAnnotation
}

glob HEAVY_LINE = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━";
glob THIN_LINE = "─────────";
glob TREND_LINE = "──────────────────────────";

def confidence_label(score: int) -> str {
    if score >= 70 {
        return "strong";
    } elif score >= 45 {
        return "moderate";
    }
    return "weak";
}

def detect_trend(labels: list[str]) -> str {
    if len(labels) < 2 {
        return "(insufficient history)";
    }
    last: str = labels[-1];
    prev: str = labels[-2];
    rank: dict[str, int] = {"weak": 0, "moderate": 1, "strong": 2};
    if rank.get(last, 0) > rank.get(prev, 0) {
        return "(accelerating ▲)";
    } elif rank.get(last, 0) < rank.get(prev, 0) {
        return "(decelerating ▼)";
    }
    return "(stable)";
}

def format_agent_line(agent_name: str, confidence: int, finding: str) -> str {
    conf_str: str = f"{confidence}%";
    padded_name: str = f"{agent_name:<15}";
    first_line: str = finding.split("\n")[0] if finding else "no data";
    return f"[{padded_name} {conf_str:>3}]  {first_line}";
}

def format_trend_line(snapshots: list[TemporalSnapshot], snap_side: str, depth: int) -> str {
    if len(snapshots) == 0 {
        return f"{snap_side.capitalize()} coalition: [no prior data]";
    }
    sorted_snaps: list[TemporalSnapshot] = sorted(
        snapshots,
        key=lambda (s: TemporalSnapshot) { s.run_number; }
    );
    recent: list[TemporalSnapshot];
    if len(sorted_snaps) >= depth {
        recent = sorted_snaps[-depth:];
    } else {
        recent = sorted_snaps;
    }
    labels: list[str] = [confidence_label(s.confidence) for s in recent];
    trend: str = detect_trend(labels);
    labels_str: str = " → ".join([f"{l:<8}" for l in labels]);
    return f"{snap_side.capitalize()} coalition: [{labels_str}]  {trend}";
}

def format_bull_section(bull: BullNode) -> list[str] {
    lines: list[str] = [];
    lines.append(f"BULL CASE                                              [Coalition Confidence: {bull.confidence}%]");
    lines.append(THIN_LINE);
    lines.append(format_agent_line("BullNewsAgent", bull.news_confidence, bull.news_finding));
    lines.append(format_agent_line("BullQuantAgent", bull.quant_confidence, bull.quant_finding));
    lines.append(format_agent_line("BullMacroAgent", bull.macro_confidence, bull.macro_finding));
    return lines;
}

def format_bear_section(bear: BearNode) -> list[str] {
    lines: list[str] = [];
    lines.append(f"BEAR CASE                                              [Coalition Confidence: {bear.confidence}%]");
    lines.append(THIN_LINE);
    lines.append(format_agent_line("BearNewsAgent", bear.news_confidence, bear.news_finding));
    lines.append(format_agent_line("BearQuantAgent", bear.quant_confidence, bear.quant_finding));
    lines.append(format_agent_line("BearMacroAgent", bear.macro_confidence, bear.macro_finding));
    return lines;
}

def format_verdict_section(verdict: VerdictNode) -> list[str] {
    lines: list[str] = [];
    lines.append("JUDGE'S RULING");
    lines.append(TREND_LINE);
    lines.append(f"Verdict:         {verdict.verdict.upper()}");
    lines.append(f"Confidence:      {verdict.judge_confidence}%");
    lines.append(f"Rationale:       {verdict.rationale}");
    if verdict.condition {
        lines.append(f"Condition:       {verdict.condition}");
    }
    return lines;
}

walker MemoFormatter {
    has snapshot_depth: int = 4;
    has asset_memos: list[str] = [];
    has portfolio_annotation: str = "";

    can enter_portfolio with PortfolioNode entry {
        annotations: list[PortfolioAnnotation] = [->:HasAnnotation:->][?:PortfolioAnnotation];
        if len(annotations) > 0 {
            sorted_ann: list[PortfolioAnnotation] = sorted(
                annotations,
                key=lambda (a: PortfolioAnnotation) { a.run_number; }
            );
            self.portfolio_annotation = sorted_ann[-1].annotation;
        }
        visit [->:BelongsToPortfolio:->][?:Asset];
    }

    can enter_asset with Asset entry {
        bull_nodes: list[BullNode] = [->:HasCoalition:side=="bull":->][?:BullNode];
        bear_nodes: list[BearNode] = [->:HasCoalition:side=="bear":->][?:BearNode];
        verdict_nodes: list[VerdictNode] = [->:HasVerdict:->][?:VerdictNode];

        ticker: str = here.ticker;
        lines: list[str] = [];

        lines.append(HEAVY_LINE);
        lines.append(f"TICKER: {ticker}");
        lines.append(HEAVY_LINE);
        lines.append("");

        # Bull case
        if len(bull_nodes) > 0 {
            lines = lines + format_bull_section(bull_nodes[0]);
        } else {
            lines.append("BULL CASE                                              [Coalition Confidence: 0%]");
            lines.append(THIN_LINE);
            lines.append("  No bull coalition data available.");
        }
        lines.append("");

        # Bear case
        if len(bear_nodes) > 0 {
            lines = lines + format_bear_section(bear_nodes[0]);
        } else {
            lines.append("BEAR CASE                                              [Coalition Confidence: 0%]");
            lines.append(THIN_LINE);
            lines.append("  No bear coalition data available.");
        }
        lines.append("");

        # Signal trend
        lines.append(f"SIGNAL TREND (last {self.snapshot_depth} runs)");
        lines.append(TREND_LINE);

        bull_snapshots: list[TemporalSnapshot] = [];
        bear_snapshots: list[TemporalSnapshot] = [];
        if len(bull_nodes) > 0 {
            bull_snapshots = [bull_nodes[0] ->:HasSnapshot:->][?:TemporalSnapshot];
        }
        if len(bear_nodes) > 0 {
            bear_snapshots = [bear_nodes[0] ->:HasSnapshot:->][?:TemporalSnapshot];
        }
        lines.append(format_trend_line(bull_snapshots, "bull", self.snapshot_depth));
        lines.append(format_trend_line(bear_snapshots, "bear", self.snapshot_depth));
        lines.append("");

        # Judge ruling
        if len(verdict_nodes) > 0 {
            lines = lines + format_verdict_section(verdict_nodes[0]);
        } else {
            lines.append("JUDGE'S RULING");
            lines.append(TREND_LINE);
            lines.append("  No verdict rendered.");
        }
        lines.append(HEAVY_LINE);

        self.asset_memos.append("\n".join(lines));
    }

    can exit_portfolio with PortfolioNode exit {
        parts: list[str] = self.asset_memos;

        if self.portfolio_annotation {
            annotation_block: str = f"{HEAVY_LINE}\nPORTFOLIO ANNOTATION\n{TREND_LINE}\n{self.portfolio_annotation}\n{HEAVY_LINE}";
            parts.append(annotation_block);
        }

        report "\n\n".join(parts);
    }
}
