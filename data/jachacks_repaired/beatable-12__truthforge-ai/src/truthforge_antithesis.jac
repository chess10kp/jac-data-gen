"""
TruthForge AI - Antithesis Walker
Attacks each thesis claim INDIVIDUALLY with specific counter-arguments.
All counter-claims come from Gemini API — no hardcoded placeholders.
"""

import from truthforge_nodes { * }
import from truthforge_config { * }

walker AntithesisWalker {
    has question_text: str = "";
    has thesis_claims: list[dict] = [];
    has counter_claims: list[dict] = [];
    has session_id: str = "";

    def attack_claims() {
        print(f"[ANTITHESIS] Attacking {len(self.thesis_claims)} thesis claims individually...");

        # Counter-claims are populated by Gemini API call in TypeScript layer.

        for (i, counter) in enumerate(self.counter_claims) {
            target_idx = counter.get("targets_claim_index", 0);
            target_claim = "";
            if target_idx < len(self.thesis_claims) {
                target_claim = self.thesis_claims[target_idx].get("statement", "")[:40];
            }
            print(f"  Counter {i+1} → attacks Claim {target_idx + 1} ({target_claim}...)");
            print(f"    Statement: {counter.get('statement', '')[:80]}...");
            print(f"    Attack type: {counter.get('attack_type', 'logical')}");
            print(f"    Strength: {counter.get('strength', 0):.2f}");
        }
    }

    def synthesize_antithesis() -> dict {
        return {
            "total_counter_claims": len(self.counter_claims),
            "counter_claims": self.counter_claims,
            "primary_counter": self.counter_claims[0] if len(self.counter_claims) > 0 else {},
            "supporting_counters": self.counter_claims[1:] if len(self.counter_claims) > 1 else []
        };
    }

    def generate_antithesis(thesis_claims: list[dict], session_id: str = "") -> dict {
        self.thesis_claims = thesis_claims;
        self.session_id = session_id;

        print("[ANTITHESIS] ===== ANTITHESIS WALKER STARTING =====");

        self.attack_claims();
        result = self.synthesize_antithesis();

        print(f"[ANTITHESIS] Total counter-claims: {result['total_counter_claims']}");
        print("[ANTITHESIS] ===== ANTITHESIS WALKER COMPLETE =====");

        return result;
    }
}
