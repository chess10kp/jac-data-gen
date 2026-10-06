"""Appeal node — a formal Medicare appeal submission.

Level 1 = Redetermination (CMS-20027, 120-day deadline)
Level 2 = Reconsideration via QIC (CMS-20033, 180-day deadline)
Level 3 = ALJ Hearing
Level 4 = Medicare Appeals Council
Level 5 = Federal District Court
"""

node Appeal {
    has appeal_id: str = "",
        appeal_level: int = 1,
        form_type: str = "CMS-20027",   # CMS-20027 | CMS-20033
        submission_date: str = "",
        due_date: str = "",             # filing deadline
        decision_date: str = "",
        decision: str = "PENDING",
        # PENDING | FAVORABLE | PARTIALLY_FAVORABLE | UNFAVORABLE | DISMISSED
        decision_rationale: str = "",
        amount_requested: float = 0.0,
        amount_awarded: float = 0.0,
        letter_content: str = "",       # generated appeal letter text
        supporting_docs: list[str] = [],
        submitted_to: str = "",         # MAC name / QIC name / ALJ office
        tracking_number: str = "",
        created_at: str = "";
}
