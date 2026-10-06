"""Edge archetypes connecting BinSight domain nodes."""

edge Serves {
    has started_at: str = "";
    has position: int = 0;
}

edge Hosts {
    has since: str = "";
    has recurring: bool = True;
}

edge Features {
    has rotation_slot: int = 0;
    has first_seen_on: str = "";
}

edge Placed {
    has zone_label: str = "";
    has since: str = "";
}

edge Captured {
    has captured_at: str;
    has camera_operator: str = "";
}

edge Contains {
    has line_index: int = 0;
    has auto_detected: bool = True;
}

edge MatchedTo {
    has confidence: float = 0.0;
    has matched_by: str = "llm";
}

edge Suggests {
    has generated_at: str;
    has confidence: float = 0.0;
    has model_name: str = "";
}

edge Reviewed {
    has reviewed_at: str;
    has decision: str = "pending";
    has notes: str = "";
}

edge Belongs {
    has role: str = "member";
    has since: str = "";
}

edge Scraped {
    has scraped_at: str;
    has http_status: int = 200;
}

edge CalibratedBy {
    has calibrated_at: str = "";
    has notes: str = "";
}

edge TriggeredBy {
    has triggered_at: str;
    has rule_name: str = "";
}

edge Observed {
    has observed_at: str;
    has source: str = "analysis";
}

edge PrecededBy {
    has lag_days: int = 7;
    has correlation: float = 0.0;
}
