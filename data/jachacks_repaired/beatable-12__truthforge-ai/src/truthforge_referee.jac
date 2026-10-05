"""
TruthForge AI - Referee Walker
Evaluates debate quality with real scores derived from actual agent outputs.
Scores: logic_strength, evidence_strength, assumption_risk, agreement_level
"""

import from truthforge_nodes { * }
import from truthforge_config { * }

walker RefereeWalker {
    has thesis_claims: list[dict] = [];
    has counter_claims: list[dict] = [];
    has evidence_nodes: list[dict] = [];
    has verdict: dict = {};
    has session_id: str = "";

    def evaluate_debate() {
        print("[REFEREE] ===== REFEREE WALKER STARTING =====");
        print(f"[REFEREE] Evaluating {len(self.thesis_claims)} claims vs {len(self.counter_claims)} counter-claims");
        print(f"[REFEREE] Evidence pieces: {len(self.evidence_nodes)}");

        # Verdict is populated by Gemini API call in TypeScript layer.

        if len(self.verdict.keys()) > 0 {
            print(f"[REFEREE] Logic Strength: {self.verdict.get('logic_strength', 0):.2f}");
            print(f"[REFEREE] Evidence Strength: {self.verdict.get('evidence_strength', 0):.2f}");
            print(f"[REFEREE] Assumption Risk: {self.verdict.get('assumption_risk', 0):.2f}");
            print(f"[REFEREE] Agreement Level: {self.verdict.get('agreement_level', 0):.2f}");
            print(f"[REFEREE] Stronger Position: {self.verdict.get('stronger_position', 'balanced')}");

            findings = self.verdict.get("key_findings", []);
            if len(findings) > 0 {
                print("[REFEREE] Key Findings:");
                for finding in findings {
                    print(f"  - {finding}");
                }
            }

            print(f"[REFEREE] Reasoning: {self.verdict.get('reasoning', '')[:100]}");
        }

        print("[REFEREE] ===== REFEREE WALKER COMPLETE =====");
    }

    def evaluate(
        thesis_claims: list[dict],
        counter_claims: list[dict],
        evidence_nodes: list[dict],
        session_id: str = ""
    ) -> dict {
        self.thesis_claims = thesis_claims;
        self.counter_claims = counter_claims;
        self.evidence_nodes = evidence_nodes;
        self.session_id = session_id;

        self.evaluate_debate();

        return self.verdict;
    }
}
