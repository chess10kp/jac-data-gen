# agents/damage_estimator.jac

import from byllm.llm { Model }
import from nodes.data_nodes {
    EvidenceNode,
    TimelineNode,
    FalsityNode,
    ScientorNode,
    MaterialityNode,
    CausationNode,
    CaseMemoNode
}
import from helpers { parse_json, calculate_damages }

glob llm = Model(model_name="claude-haiku-4-5-20251001");

node DamageEstimatorAgent {
    has damage_complete: bool = False;

    """
    You are a False Claims Act damages expert.

    Calculate total damages based on the evidence and timeline provided.

    The False Claims Act allows:
    - Treble damages: actual damages x 3
    - Civil penalties: $13,946 to $27,894 per false claim

    Return a JSON object with:
    - total_false_claims: integer number of false claims
    - actual_cpt_code: the correct CPT code that should have been billed
    - billed_cpt_code: the CPT code that was actually billed
    - overpayment_per_claim: float dollar amount overbilled per claim
    - base_damages: float total overpayment amount
    - treble_damages: float base_damages x 3
    - min_penalties: float minimum civil penalties (13946 x claims)
    - max_penalties: float maximum civil penalties (27894 x claims)
    - total_min_exposure: float treble_damages + min_penalties
    - total_max_exposure: float treble_damages + max_penalties
    - defendant: name of the fraudulent provider
    - case_summary: two sentence summary of the fraud

    Return only valid JSON. No other text.
    """
    def estimate_damages(
        evidence_items: list[dict],
        timeline: dict,
        billing_records: str
    ) -> str by llm();

    can run with entry {
        print("Damage Estimator firing!");

        evidence_items: list[dict] = [];
        for e in [root -->][?:EvidenceNode] {
            evidence_items.append({
                "type": e.evidence_type,
                "desc": e.description,
                "source": e.source_doc
            });
        }

        timeline: dict = {};
        for t in [root -->][?:TimelineNode] {
            timeline = {
                "fraud_start": t.fraud_start,
                "fraud_end": t.fraud_end,
                "total_duration_months": t.total_duration_months
            };
        }

        print("Evidence items: " + str(len(evidence_items)));

        raw = self.estimate_damages(
            evidence_items,
            timeline,
            "billing_records.csv"
        );
        print("Damage LLM output received");

        damage_data = parse_json(raw);

        # Compute overall_strength from FCA scores
        total_score = 0.0;
        count = 0;
        for f in [root -->][?:FalsityNode] {
            total_score = total_score + f.strength_score;
            count = count + 1;
        }
        for s in [root -->][?:ScientorNode] {
            total_score = total_score + s.strength_score;
            count = count + 1;
        }
        for m in [root -->][?:MaterialityNode] {
            total_score = total_score + m.strength_score;
            count = count + 1;
        }
        for c in [root -->][?:CausationNode] {
            total_score = total_score + c.strength_score;
            count = count + 1;
        }
        overall = total_score / count if count > 0 else 0.0;

        # Don't trust the LLM's arithmetic on large dollar figures - recompute
        # treble damages and exposure deterministically from the FCA formulas
        # using only the facts (claim count, base damages) the LLM extracted.
        claims          = int(damage_data.get("total_false_claims", 0));
        base_damages    = float(damage_data.get("base_damages", 0.0));
        treble_damages  = base_damages * 3;
        min_penalties   = 13946.0 * claims;
        max_penalties   = 27894.0 * claims;
        total_exposure  = treble_damages + max_penalties;

        memo = CaseMemoNode();
        memo.defendant          = damage_data.get("defendant", "Unknown");
        memo.total_false_claims = claims;
        memo.base_damages       = base_damages;
        memo.treble_damages     = treble_damages;
        memo.per_claim_penalty  = 13946.0;
        memo.total_exposure     = total_exposure;
        memo.overall_strength   = overall;
        memo.gap_analysis       = [];
        memo.case_summary       = damage_data.get("case_summary", "");

        root ++> memo;

        self.damage_complete = True;
        visitor.damage_done = True;
        print("Damage estimation complete!");
        print("Defendant: " + memo.defendant);
        print("False claims: " + str(memo.total_false_claims));
        print("Base damages: $" + str(memo.base_damages));
        print("Treble damages: $" + str(memo.treble_damages));
        print("Total exposure: $" + str(memo.total_exposure));
        print("Overall strength: " + str(memo.overall_strength));
    }
}
