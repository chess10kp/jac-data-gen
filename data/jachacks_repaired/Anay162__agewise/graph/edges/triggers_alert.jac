"""triggers_alert edge — Transaction/Claim → ScamAlert."""

edge triggers_alert {
    has detection_method: str = "";   # rule_based | llm | pattern_match
}
