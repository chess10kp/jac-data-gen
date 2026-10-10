# agents/timeline_agent.jac

import from byllm.llm { Model }
import from nodes.data_nodes {
    EvidenceNode,
    TimelineNode
}
import from helpers { parse_json }

glob llm = Model(model_name="claude-haiku-4-5-20251001");

node TimelineAgent {
    has timeline_complete: bool = False;

    """
    You are a legal timeline expert analyzing healthcare fraud evidence.

    Build a chronological fraud timeline from the provided evidence.

    Return a JSON object with:
    - events: list of {"date": "YYYY-MM-DD", "event": "description", "amount": 0.0}
    - fraud_start: "YYYY-MM-DD" when fraud began
    - fraud_end: "YYYY-MM-DD" when fraud ended or was discovered
    - total_duration_months: integer number of months fraud ran
    - summary: one paragraph describing the fraud timeline

    Order events chronologically oldest to newest.
    Return only valid JSON. No other text.
    """
    def build_timeline(
        evidence_items: list[dict],
        document_content: list[str]
    ) -> str by llm();

    can run with entry {
        print("Timeline Agent firing!");

        evidence_items: list[dict] = [];
        for e in [root -->][?:EvidenceNode] {
            evidence_items.append({
                "type": e.evidence_type,
                "desc": e.description,
                "source": e.source_doc,
                "confidence": e.confidence
            });
        }

        print("Evidence items found: " + str(len(evidence_items)));

        if len(evidence_items) == 0 {
            print("No evidence found - skipping timeline");
            self.timeline_complete = True;
            visitor.timeline_done = True;
            return;
        }

        raw = self.build_timeline(evidence_items, []);
        print("Timeline LLM output received");

        timeline_data = parse_json(raw);

        tl = TimelineNode();
        tl.events = [];
        tl.fraud_start = "unknown";
        tl.fraud_end = "unknown";
        tl.total_duration_months = 0;

        if "events" in timeline_data {
            tl.events = timeline_data["events"];
        }
        if "fraud_start" in timeline_data {
            tl.fraud_start = timeline_data["fraud_start"];
        }
        if "fraud_end" in timeline_data {
            tl.fraud_end = timeline_data["fraud_end"];
        }
        if "total_duration_months" in timeline_data {
            tl.total_duration_months = timeline_data["total_duration_months"];
        }

        root ++> tl;

        self.timeline_complete = True;
        visitor.timeline_done = True;
        print("Timeline complete!");
        print("Fraud start: " + tl.fraud_start);
        print("Fraud end: " + tl.fraud_end);
        print("Duration: " + str(tl.total_duration_months) + " months");
    }
}