"""
TruthForge AI - Synthesis Walker
Generates the final structured output shown to the user.
Output format: Analysis → Perspective Exploration → Supporting Factors →
               Counterarguments → Historical Context → Confidence Assessment → Final Answer

NEVER uses template phrases like "The evidence suggests X and Y are interconnected"
"""

import from truthforge_nodes { * }
import from truthforge_config { * }

walker SynthesisWalker {
    has question_text: str = "";
    has question_type: str = "factual";
    has thesis_claims: list[dict] = [];
    has counter_claims: list[dict] = [];
    has evidence_nodes: list[dict] = [];
    has verdict: dict = {};
    has session_id: str = "";

    def build_synthesis() -> dict {
        print("[SYNTHESIS] Building structured final analysis...");
        print(f"[SYNTHESIS] Question: {self.question_text[:50]}...");
        print(f"[SYNTHESIS] Integrating {len(self.thesis_claims)} claims, {len(self.counter_claims)} counter-claims, {len(self.evidence_nodes)} evidence items");

        # Synthesis result is populated by Gemini API call in TypeScript layer.
        # The result dict will contain all sections listed above.

        return {};
    }

    def render_synthesis(result: dict) {
        print("[SYNTHESIS] ===== FINAL SYNTHESIS =====");

        if "analysis" in result {
            print(f"\nANALYSIS:\n{result['analysis']}");
        }

        if "perspective_exploration" in result and result["perspective_exploration"] != "" {
            print(f"\nPERSPECTIVE EXPLORATION:\n{result['perspective_exploration']}");
        }

        if "supporting_factors" in result {
            print("\nSUPPORTING FACTORS:");
            for factor in result["supporting_factors"] {
                print(f"  ✓ {factor}");
            }
        }

        if "counterarguments" in result {
            print("\nCOUNTERARGUMENTS:");
            for counter in result["counterarguments"] {
                print(f"  ✗ {counter}");
            }
        }

        if "historical_context" in result and result["historical_context"] != "" {
            print(f"\nHISTORICAL CONTEXT:\n{result['historical_context']}");
        }

        if "confidence_assessment" in result and result["confidence_assessment"] != "" {
            print(f"\nCONFIDENCE ASSESSMENT:\n{result['confidence_assessment']}");
        }

        if "final_answer" in result {
            print(f"\nFINAL ANSWER:\n{result['final_answer']}");
        }

        print(f"\nCONFIDENCE: {result.get('confidence', 'Moderate')}");
        print("[SYNTHESIS] ===== END SYNTHESIS =====");
    }

    def synthesize(
        question_text: str,
        thesis_claims: list[dict],
        counter_claims: list[dict],
        evidence_nodes: list[dict],
        verdict: dict,
        session_id: str = ""
    ) -> dict {
        self.question_text = question_text;
        self.thesis_claims = thesis_claims;
        self.counter_claims = counter_claims;
        self.evidence_nodes = evidence_nodes;
        self.verdict = verdict;
        self.session_id = session_id;

        print("[SYNTHESIS] ===== SYNTHESIS WALKER STARTING =====");

        result = self.build_synthesis();
        self.render_synthesis(result);

        print("[SYNTHESIS] ===== SYNTHESIS WALKER COMPLETE =====");

        return result;
    }
}
