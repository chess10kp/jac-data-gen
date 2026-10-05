"""
TruthForge AI - Evidence Walker
Gathers structured evidence using Gemini, search capability, and graph memory.
Returns: { source_count, source_titles[], evidence[] }
No hardcoded evidence — all data comes from Gemini API.
"""

import from truthforge_nodes { * }
import from truthforge_config { * }

walker EvidenceWalker {
    has question_text: str = "";
    has thesis_claims: list[dict] = [];
    has counter_claims: list[dict] = [];
    has gathered_evidence: list[dict] = [];
    has source_count: int = 0;
    has source_titles: list[str] = [];
    has session_id: str = "";

    def gather_evidence() {
        print("[EVIDENCE] ===== EVIDENCE WALKER STARTING =====");
        print(f"[EVIDENCE] Question: {self.question_text[:50]}...");
        print(f"[EVIDENCE] Thesis claims to search: {len(self.thesis_claims)}");
        print(f"[EVIDENCE] Counter-claims to search: {len(self.counter_claims)}");

        # Evidence is populated by Gemini API call in TypeScript layer.

        self.source_count = len(self.source_titles);

        print(f"[EVIDENCE] Sources found: {self.source_count}");
        for title in self.source_titles {
            print(f"  - {title}");
        }

        print(f"[EVIDENCE] Evidence items: {len(self.gathered_evidence)}");
        for (i, ev) in enumerate(self.gathered_evidence) {
            print(f"  Evidence {i+1}:");
            print(f"    Content: {ev.get('content', '')[:60]}...");
            print(f"    Source: {ev.get('source_title', 'Unknown')}");
            print(f"    Type: {ev.get('source_type', 'general')}");
            print(f"    Supports: {ev.get('supports', 'both')}");
            print(f"    Credibility: {ev.get('credibility', 0):.2f}");
        }

        print("[EVIDENCE] ===== EVIDENCE WALKER COMPLETE =====");
    }

    def get_structured_result() -> dict {
        return {
            "source_count": self.source_count,
            "source_titles": self.source_titles,
            "evidence": self.gathered_evidence
        };
    }

    def gather(
        thesis_claims: list[dict],
        counter_claims: list[dict],
        session_id: str = ""
    ) -> list[dict] {
        self.thesis_claims = thesis_claims;
        self.counter_claims = counter_claims;
        self.session_id = session_id;

        self.gather_evidence();

        return self.gathered_evidence;
    }
}
