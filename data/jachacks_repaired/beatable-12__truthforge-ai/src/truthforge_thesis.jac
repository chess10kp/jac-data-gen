"""
TruthForge AI - Thesis Walker
Generates 2-4 CONCRETE supporting claims from the question.
All claims come from Gemini API — no hardcoded placeholders.
"""

import from truthforge_nodes { * }
import from truthforge_config { * }

walker ThesisWalker {
    has question_text: str = "";
    has question_type: str = "factual";
    has domain: str = "general";
    has memory_context: str = "";
    has generated_claims: list[dict] = [];
    has session_id: str = "";

    def generate_claims() {
        print(f"[THESIS] Generating concrete claims for: {self.question_text[:50]}...");
        print(f"[THESIS] Question type: {self.question_type}, Domain: {self.domain}");

        # Claims are populated by Gemini API call in TypeScript layer.
        # Each claim has: statement, reasoning, strength
        # The prompt demands specificity and forbids template language.

        print(f"[THESIS] Generated {len(self.generated_claims)} claims");
        for (i, claim) in enumerate(self.generated_claims) {
            print(f"  Claim {i+1}: {claim.get('statement', '')[:80]}...");
            print(f"    Reasoning: {claim.get('reasoning', '')[:60]}");
            print(f"    Strength: {claim.get('strength', 0):.2f}");
        }
    }

    def synthesize_thesis() -> dict {
        return {
            "total_claims": len(self.generated_claims),
            "claims": self.generated_claims,
            "primary_claim": self.generated_claims[0] if len(self.generated_claims) > 0 else {},
            "supporting_claims": self.generated_claims[1:] if len(self.generated_claims) > 1 else []
        };
    }

    def generate_thesis(session_id: str = "") -> dict {
        self.session_id = session_id;

        print("[THESIS] ===== THESIS WALKER STARTING =====");

        self.generate_claims();
        result = self.synthesize_thesis();

        print(f"[THESIS] Total claims: {result['total_claims']}");
        print("[THESIS] ===== THESIS WALKER COMPLETE =====");

        return result;
    }
}
