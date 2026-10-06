"""Dispute node — a detected billing error or coverage dispute.

Created by audit walkers (fee_schedule_auditor, ncci_ptp_checker, etc.)
when they find problems. Progresses through appeal levels 1→5.
"""

node Dispute {
    has dispute_id: str = "",
        error_type: str = "",
        # FEE_SCHEDULE_OVERAGE | NCCI_PTP_VIOLATION | MUE_VIOLATION |
        # DUPLICATE_CHARGE | NOT_COVERED | WRONG_MODIFIER | CODING_ERROR
        description: str = "",
        payer_name: str = "",
        amount_disputed: float = 0.0,
        expected_amount: float = 0.0,
        appeal_level: int = 0,          # 0=not started, 1-5=appeal level
        status: str = "OPEN",
        # OPEN | IN_PROGRESS | APPEALED | RESOLVED | WITHDRAWN | ESCALATED
        deadline: str = "",             # next action deadline
        flagged_date: str = "",
        resolved_date: str = "",
        resolution_amount: float = 0.0,
        evidence: list[str] = [],       # doc IDs or descriptions
        citations: list[str] = [],      # regulatory citations (42 CFR, etc.)
        confidence_score: float = 0.0,  # 0.0-1.0 audit confidence
        severity: str = "MEDIUM";       # LOW | MEDIUM | HIGH | CRITICAL
}
