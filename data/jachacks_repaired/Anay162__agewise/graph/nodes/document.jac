"""Document node — raw incoming document before structured extraction.

Stores original content plus classification result from the
document_classify walker (via by llm()).
"""

node Document {
    has doc_id: str = "",
        doc_type: str = "",             # Explicit document type (for generated docs)
        title: str = "",                # Human-readable title
        raw_content: str = "",          # full text extracted from doc
        raw_text: str = "",             # Alias for raw_content (normalized field)
        source: str = "",               # email | upload | portal | mail_scan | generated
        source_channel: str = "email",
        classification: str = "UNKNOWN",
        # DocumentCategory: EOB | MSN_PART_A | MSN_PART_B | MEDICAL_BILL |
        # CMS1500_CLAIM | UB04_CLAIM | INSURANCE_NOTICE | POLICY_CHANGE |
        # HIPAA_AUTH | POWER_OF_ATTORNEY | WILL | TRUST | BENEFICIARY_FORM |
        # LEGAL_NOTICE | FINANCIAL_STATEMENT | BENEFIT_APPLICATION |
        # APPOINTMENT_CONFIRMATION | PHARMACY_NOTIFICATION | REFILL_REMINDER |
        # SCAM_COMMUNICATION | UNKNOWN
        original_filename: str = "",
        mime_type: str = "",
        ingested_at: str = "",
        processed: bool = False,
        plain_english_summary: str = "",
        embedding_id: str = "",
        content_hash: str = "";         # for deduplication
}
