"""Judge Agent — neutral synthesis walker."""

import from ..graph.nodes { Asset, BullNode, BearNode, TemporalSnapshot, VerdictNode }
import from ..graph.edges { HasCoalition, HasSnapshot, HasVerdict }
import from ..prompts.judge_prompts { JudgeVerdict, synthesize_verdict }

def confidence_label(score: int) -> str {
    if score >= 70 {
        return "strong";
    } elif score >= 45 {
        return "moderate";
    }
    return "weak";
}

def build_momentum(snapshots: list[TemporalSnapshot]) -> str {
    # Build a momentum string from sorted snapshots, e.g. "weak -> moderate -> strong"
    if len(snapshots) == 0 {
        return "no prior data";
    }
    sorted_snaps = sorted(snapshots, key=lambda (s: TemporalSnapshot) { s.run_number; });
    labels = [confidence_label(s.confidence) for s in sorted_snaps];
    return " -> ".join(labels);
}

walker JudgeWalker {
    has insufficient_data_threshold: int = 35;

    can enter_asset with Asset entry {
        bull_nodes = [->:HasCoalition:side=="bull":->][?:BullNode];
        bear_nodes = [->:HasCoalition:side=="bear":->][?:BearNode];

        if len(bull_nodes) == 0 or len(bear_nodes) == 0 {
            verdict_node = here ++> VerdictNode(
                verdict="insufficient data",
                judge_confidence=0,
                rationale="Missing coalition data — one or both sides did not deposit findings.",
                condition=""
            );
            report verdict_node[0];
            disengage;
        }

        bull = bull_nodes[0];
        bear = bear_nodes[0];

        # Collect temporal snapshots for momentum detection
        bull_snapshots = [bull ->:HasSnapshot:->][?:TemporalSnapshot];
        bear_snapshots = [bear ->:HasSnapshot:->][?:TemporalSnapshot];

        bull_momentum = build_momentum(bull_snapshots);
        bear_momentum = build_momentum(bear_snapshots);

        # Epistemic humility — both sides low confidence
        if bull.confidence < self.insufficient_data_threshold
           and bear.confidence < self.insufficient_data_threshold {
            verdict_node = here +>:HasVerdict:+> VerdictNode(
                verdict="insufficient data",
                judge_confidence=0,
                rationale=f"Both coalitions returned low confidence (bull: {bull.confidence}%, bear: {bear.confidence}%). Neither side found sufficient evidence to build a credible case. Re-evaluate after new data.",
                condition=""
            );
            report verdict_node[0];
            disengage;
        }

        # Call LLM for verdict synthesis
        result = synthesize_verdict(
            ticker=here.ticker,
            bull_argument=bull.argument,
            bull_confidence=bull.confidence,
            bear_argument=bear.argument,
            bear_confidence=bear.confidence,
            bull_momentum=bull_momentum,
            bear_momentum=bear_momentum
        );

        # Create verdict node and attach to asset
        verdict_node = here +>:HasVerdict:+> VerdictNode(
            verdict=result.verdict,
            judge_confidence=result.judge_confidence,
            rationale=result.rationale,
            condition=result.condition
        );

        report verdict_node[0];
    }
}
