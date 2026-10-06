"""ScamAlert node — a detected scam or fraud attempt targeting the patient.

Created by the scam_detection_pipeline when transactions, communications,
or patterns match known elder fraud patterns.
"""

node ScamAlert {
    has alert_id: str = "",
        threat_type: str = "",
        # MEDICARE_IMPERSONATION | FAKE_BILLING | PHISHING |
        # GRANDPARENT_SCAM | TECH_SUPPORT | ROMANCE | INVESTMENT | IDENTITY_THEFT
        confidence_score: float = 0.0,
        description: str = "",
        evidence: list[str] = [],
        source: str = "",               # transaction_id | email_id | call_id
        resolution: str = "OPEN",
        # OPEN | INVESTIGATING | REPORTED | RESOLVED | FALSE_POSITIVE
        reported_to: list[str] = [],    # FTC | local_police | Medicare
        amount_at_risk: float = 0.0,
        amount_lost: float = 0.0,
        detected_at: str = "",
        resolved_at: str = "";
}
