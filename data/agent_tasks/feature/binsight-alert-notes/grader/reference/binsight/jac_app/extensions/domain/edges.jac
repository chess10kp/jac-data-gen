"""Edge archetypes connecting BinSight domain nodes."""

edge Serves: any --> any {
    has started_at: str = "";
    has position: int = 0;
}

edge Hosts: any --> any {
    has since: str = "";
    has recurring: bool = True;
}

edge Features: any --> any {
    has rotation_slot: int = 0;
    has first_seen_on: str = "";
}

edge Placed: any --> any {
    has zone_label: str = "";
    has since: str = "";
}

edge Captured: any --> any {
    has captured_at: str;
    has camera_operator: str = "";
}

edge Contains: any --> any {
    has line_index: int = 0;
    has auto_detected: bool = True;
}

edge MatchedTo: any --> any {
    has confidence: float = 0.0;
    has matched_by: str = "llm";
}

edge Suggests: any --> any {
    has generated_at: str;
    has confidence: float = 0.0;
    has model_name: str = "";
}

edge Reviewed: any --> any {
    has reviewed_at: str;
    has decision: str = "pending";
    has notes: str = "";
}

edge Belongs: any --> any {
    has role: str = "member";
    has since: str = "";
}

edge Scraped: any --> any {
    has scraped_at: str;
    has http_status: int = 200;
}

edge CalibratedBy: any --> any {
    has calibrated_at: str = "";
    has notes: str = "";
}

edge TriggeredBy: any --> any {
    has triggered_at: str;
    has rule_name: str = "";
}

edge Observed: any --> any {
    has observed_at: str;
    has source: str = "analysis";
}

edge PrecededBy: any --> any {
    has lag_days: int = 7;
    has correlation: float = 0.0;
}

edge AnnotatedBy: any --> any {
    has added_at: str = "";
}
