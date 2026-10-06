"""All by llm() function signatures for AI-powered reasoning tasks.

Each function uses Jac's Meaning Typed Programming: the compiler extracts
semantics from the function name, type annotations, and docstring to build
the LLM prompt automatically. No manual prompt engineering needed.

Model: claude-4.6-sonnet via OpenRouter (configured via OPENROUTER_API_KEY env var)
"""

import from os { environ }
import from jaclang.byllm.lib { Model }

glob llm = Model(
    model_name="openrouter/anthropic/claude-4.6-sonnet",
    api_key=environ.get("OPENROUTER_API_KEY", "")
);

# ═══════════════════════════════════════════════════════════════
# LAYER 1 — Document Intake & Understanding
# ═══════════════════════════════════════════════════════════════

def classify_document(
    raw_text: str,
    source_metadata: dict
) -> str by llm(model=llm);
sem classify_document = """Classify a healthcare/legal document into one of these exact categories:
   EOB, MSN_PART_A, MSN_PART_B, MEDICAL_BILL, CMS1500_CLAIM, UB04_CLAIM,
   INSURANCE_NOTICE, POLICY_CHANGE, HIPAA_AUTH, POWER_OF_ATTORNEY, WILL,
   TRUST, BENEFICIARY_FORM, LEGAL_NOTICE, FINANCIAL_STATEMENT,
   APPOINTMENT_CONFIRMATION, PRESCRIPTION_NOTICE, SCAM_COMMUNICATION, UNKNOWN.
   Consider document structure, headers, form numbers, and terminology.
   Return ONLY the category name, nothing else."""

def extract_eob_data(
    document_text: str,
    eob_type: str
) -> dict by llm(model=llm);
sem extract_eob_data = """Extract structured data from an EOB or Medicare Summary Notice (MSN).
   Return a dict with keys: claim_number, service_dates, provider_name,
   provider_npi, total_billed, medicare_approved, medicare_paid,
   patient_responsibility, non_covered_charges, benefit_days_used,
   adjudication_date, appeal_deadline, denial_codes (list), denial_reasons (list).
   For MSN_PART_A: include inpatient days, SNF days, hospice days.
   For MSN_PART_B: include each service line with CPT, date, billed, allowed, paid.
   Handle both Medicare Original (Part A/B MSN format) and Medicare Advantage EOB.
   Return empty string for any field not found."""

def extract_claim_data(
    document_text: str,
    claim_type: str
) -> dict by llm(model=llm);
sem extract_claim_data = """Extract structured claim data from a CMS-1500 or UB-04 claim form.
   For CMS-1500 return dict with: patient_name, patient_dob, insured_name,
   insured_id, provider_name, provider_npi, diagnosis_codes (list A-L),
   service_lines (list of dicts each with: line_number, date_of_service,
   place_of_service, cpt_code, modifier, diagnosis_pointer, charges, units).
   For UB-04 return dict with: patient_name, admission_date, discharge_date,
   type_of_bill, provider_name, provider_npi, diagnosis_codes (list),
   revenue_lines (list of dicts each with: revenue_code, hcpcs, description,
   service_date, units, total_charges).
   Return empty string for fields not found."""

def translate_to_plain_english(
    technical_content: str,
    content_type: str,
    reading_level: int = 6
) -> str by llm(model=llm);
sem translate_to_plain_english = """Translate medical billing or legal document content into plain English
   at approximately a 6th-grade reading level. Replace medical codes with
   plain descriptions (e.g., '99213' → 'office visit'). Explain what charges
   mean, what the patient actually owes versus what insurance paid, and flag
   anything unusual or potentially wrong. Target audience: a 75-year-old with
   no medical billing background. Use short sentences and everyday words.
   End with a 1-sentence 'Bottom line:' summary."""

def generate_weekly_digest(
    activity_summary: dict,
    pending_actions: list[dict],
    financial_summary: dict,
    alerts: list[dict]
) -> dict by llm(model=llm);
sem generate_weekly_digest = """Generate a weekly summary for an adult child caregiver managing a parent's
   healthcare. Return a dict with keys: executive_summary (2-3 sentences),
   new_documents (what arrived this week), claims_activity (claims processed,
   amounts), disputes_update (active disputes, wins, losses), upcoming_deadlines
   (sorted by date, most urgent first), financial_summary (spending, anomalies),
   alerts (scam alerts, urgent items), action_items (list of strings, things the
   adult child needs to do). Tone: professional but warm, concise, action-oriented.
   Highlight items requiring immediate attention."""

# ═══════════════════════════════════════════════════════════════
# LAYER 2 — Error Detection & Dispute Generation
# ═══════════════════════════════════════════════════════════════

def assess_billing_error(
    cpt_code: str,
    description: str,
    billed_amount: float,
    fee_schedule_rate: float,
    units: float,
    mue_limit: int,
    ncci_flags: list[str],
    modifier: str,
    diagnosis_pointers: list[str],
    diagnosis_codes: list[str]
) -> dict by llm(model=llm);
sem assess_billing_error = """Analyze a single claim line item for billing errors. Check all of:
   (1) Charge exceeds Medicare fee schedule allowable by more than 10%.
   (2) NCCI PTP edit violations — services being billed separately that should
       be bundled (describe which codes are affected).
   (3) MUE unit violations — billed units exceed medically unlikely edit limit
       (state the limit and the billed amount).
   (4) Incorrect modifier usage — modifier doesn't match CPT rules.
   (5) Diagnosis code doesn't clearly support medical necessity for the procedure.
   (6) Duplicate service suspicion.
   Return a dict with: has_error (bool), error_type (str), description (str),
   amount_disputed (float, estimated overbilling), confidence (float 0-1),
   regulatory_citation (str), recommended_action (str)."""

def generate_appeal_letter(
    dispute_description: str,
    error_type: str,
    amount_disputed: float,
    patient_name: str,
    patient_medicare_id: str,
    claim_number: str,
    service_dates: str,
    provider_name: str,
    cpt_code: str,
    denial_reason: str,
    appeal_level: int,
    prior_decision_summary: str
) -> str by llm(model=llm);
sem generate_appeal_letter = """Generate a formal Medicare appeal letter for the specified appeal level.
   Level 1 (Redetermination to MAC): Cite specific CPT/ICD codes, reference
   Medicare coverage policies (LCDs/NCDs), provide specific regulatory basis
   (42 CFR Part 405), request redetermination. Use formal business letter format.
   Level 2 (Reconsideration to QIC): Reference Level 1 decision, introduce new
   evidence or arguments, cite CMS rulings. Address to Qualified Independent
   Contractor.
   Include: patient Medicare number, claim number, dates of service, specific
   disputed amounts, regulatory basis, requested remedy.
   Add 'Supporting evidence enclosed:' section listing what to attach.
   End with signature block for patient/representative.
   Tone: formal, factual, authoritative. No fluff."""

def validate_icd10_specificity(
    icd_code: str,
    description: str,
    clinical_context: str
) -> dict by llm(model=llm);
sem validate_icd10_specificity = """Validate that an ICD-10-CM code meets coding specificity requirements.
   Check: (1) Code is not a 3-character category header (should have more digits).
   (2) Placeholder X used correctly where required. (3) 7th character present
   where required by ICD-10-CM guidelines. (4) Laterality specified when required
   (e.g., right vs. left). (5) Code is not an Excludes1 conflict.
   Return dict with: is_valid (bool), issue (str, empty if valid),
   suggested_code (str, more specific code if applicable), explanation (str)."""

# ═══════════════════════════════════════════════════════════════
# LAYER 3 — Voice Agent
# ═══════════════════════════════════════════════════════════════

def build_call_script(
    call_type: str,
    dispute_description: str,
    claim_number: str,
    cpt_code: str,
    denial_reason: str,
    insurer_name: str,
    patient_name: str,
    patient_medicare_id: str,
    prior_call_outcomes: list[str]
) -> dict by llm(model=llm);
sem build_call_script = """Generate a dynamic phone call script for the voice agent. Return a dict with:
   opening (introduction, identifying as authorized representative, verification
   info to provide), main_ask (specific request: claim number, reason for call,
   what resolution is requested), escalation_triggers (list of conditions that
   mean the agent should ask for a supervisor), fallback_positions (list of
   acceptable partial resolutions), closing (confirmation of next steps,
   reference number request, callback info).
   For billing disputes: be firm but professional. State the specific error,
   cite the Medicare fee schedule or NCCI edit, request immediate correction.
   Adapt based on prior call outcomes if provided."""

def extract_call_action_items(
    transcript: str,
    call_type: str,
    original_dispute: str
) -> dict by llm(model=llm);
sem extract_call_action_items = """Extract structured outcomes from a phone call transcript. Return dict with:
   commitments (list of strings — what the rep promised to do),
   reference_numbers (list of any reference/confirmation numbers given),
   deadlines (list of any dates/timeframes mentioned),
   documents_requested (list of anything they asked us to send),
   resolution_offered (str, what if anything they offered to resolve),
   escalation_needed (bool, whether a supervisor or formal escalation is needed),
   outcome_summary (str, 1-2 sentence summary),
   next_action (str, what we should do next based on the call)."""

# ═══════════════════════════════════════════════════════════════
# LAYER 4 — Legal & Estate
# ═══════════════════════════════════════════════════════════════

def extract_legal_document_data(
    document_text: str,
    doc_type: str
) -> dict by llm(model=llm);
sem extract_legal_document_data = """Extract structured data from legal documents.
   For WILL: executor name, beneficiaries (list), specific bequests (list),
   residuary clause, execution date, witness names.
   For TRUST: grantor, trustee, successor trustee, beneficiaries (list),
   trust assets summary, amendment provisions, incapacity provisions.
   For POWER_OF_ATTORNEY: principal, agent (attorney-in-fact), powers granted
   (list), durability clause (yes/no), effective date, springing vs. immediate.
   For HIPAA_AUTH: patient, authorized recipient, purpose, scope, sensitive info
   categories (list), expiration date, signature date.
   Return dict with all relevant fields. Use empty string for not found."""

def detect_scam_indicators(
    communication_text: str,
    sender_info: str,
    amount: float,
    transaction_date: str
) -> dict by llm(model=llm);
sem detect_scam_indicators = """Analyze a communication or financial transaction for elder fraud indicators.
   Check against known patterns: Medicare impersonation (fake Medicare calls
   asking for card numbers), fake medical billing (bills for services not
   received), phishing (urgent emails requesting payment or info),
   grandparent scam, tech support scam, investment fraud.
   Look for: urgency language, unusual payment methods (gift cards, wire),
   unsolicited contact, requests for Medicare/SSN numbers, spoofed numbers.
   Return dict with: is_scam_suspected (bool), confidence (float 0-1),
   threat_type (str), evidence (list of specific red flags found),
   recommended_action (str: report_ftc | call_family | ignore | investigate)."""

def draft_legal_amendment(
    original_document_type: str,
    original_date: str,
    change_description: str,
    jurisdiction: str,
    grantor_name: str
) -> str by llm(model=llm);
sem draft_legal_amendment = """Draft a legal document amendment for attorney review. Include:
   Amendment title (e.g., 'First Amendment to Revocable Living Trust'),
   reference to original document (date and type), recitals explaining purpose,
   specific clauses being modified with old and new language,
   signature block with date line, notary acknowledgment placeholder.
   Add prominent header: 'DRAFT FOR ATTORNEY REVIEW — NOT A LEGAL DOCUMENT.
   This draft requires review and execution by a licensed attorney.'
   Keep language formal and legally precise."""

# ═══════════════════════════════════════════════════════════════
# ADDITIONAL — Forms, Scam Analysis, Benefits Screening
# ═══════════════════════════════════════════════════════════════

def fill_appeal_form(
    form_type: str,
    dispute_id: str,
    error_type: str,
    description: str,
    amount_disputed: float,
    appeal_level: int,
    patient_name: str,
    patient_dob: str,
    medicare_id: str
) -> dict by llm(model=llm);
sem fill_appeal_form = """Fill out a Medicare appeal form with the provided dispute data.
   For CMS-20027 (Redetermination Request): return dict with all required
   fields: beneficiary_name, medicare_id, date_of_birth, claim_number,
   dates_of_service, amount_in_dispute, reason_for_request, statement_of_facts,
   representative_name (if applicable).
   For CMS-20031 (Reconsideration Request): include QIC reference number fields.
   For ALJ-HEARING-REQUEST: include OMHA form fields.
   Return a dict keyed by form field names with filled values.
   Use empty string for fields that cannot be determined from provided data."""

def analyze_scam_risk(
    transaction_description: str,
    amount: float,
    merchant: str,
    risk_flags: list[str]
) -> dict by llm(model=llm);
sem analyze_scam_risk = """Analyze a financial transaction for elder financial abuse or scam patterns.
   Consider known elder fraud vectors: Medicare impersonation, grandparent scams,
   tech support scams, romance scams, utility scams, sweepstakes fraud,
   government impersonation (IRS, SSA, DHS).
   Given the transaction description, merchant name, amount, and pre-identified
   risk flags, determine: is this transaction suspicious?
   Return dict with: is_suspicious (bool), confidence (float 0-1),
   threat_type (str, e.g. 'GOVERNMENT_IMPERSONATION' or 'WIRE_FRAUD'),
   additional_flags (list[str], any new red flags you identify),
   recommended_action (str: 'freeze_account' | 'alert_family' | 'report_ftc' | 'monitor' | 'safe')."""

def parse_appointment_email(
    email_subject: str,
    email_body: str,
    sender: str
) -> dict by llm(model=llm);
sem parse_appointment_email = """Parse an email to determine if it contains an appointment confirmation,
   reminder, or cancellation. Extract: provider_name (str), specialty (str),
   appointment_date (str, ISO YYYY-MM-DD), appointment_time (str, HH:MM),
   facility_name (str), facility_address (str), telehealth_link (str),
   confirmation_code (str), visit_purpose (str), prep_instructions (str).
   Set is_appointment_related (bool) to False and return empty strings for all
   other fields if the email is NOT about an appointment.
   Handle formats from Epic MyChart, Athena, plain-text office confirmations."""

def check_drug_interactions(
    medication_names: list[str]
) -> list by llm(model=llm);
sem check_drug_interactions = """Check for clinically significant drug-drug interactions among the provided
   medication list. For each interaction found, return a dict with:
   drug_a (str), drug_b (str),
   severity (str: CONTRAINDICATED | SERIOUS | MODERATE | MINOR),
   mechanism (str, brief explanation), clinical_effect (str),
   recommendation (str, what action to take).
   Only include pairs with severity MODERATE or higher.
   If no interactions found, return an empty list."""

def classify_subscription(
    service_name: str,
    monthly_cost: float,
    patient_age: int,
    patient_conditions: list[str]
) -> dict by llm(model=llm);
sem classify_subscription = """Classify a recurring charge for an elderly patient as one of:
   essential (mortgage, rent, health insurance, Medicare premium, utilities),
   useful (internet, phone, pharmacy delivery, grocery delivery, medical alert),
   wasteful (unused gym membership, duplicate streaming services, forgotten
   warranties, dormant memberships, magazine subscriptions),
   suspicious (unknown vendors, tech support scams, prize/lottery fees).
   Consider the patient's actual age and health conditions — a gym membership
   for a homebound 80-year-old is wasteful, internet for telehealth is essential.
   Return dict with: classification (str), reason (str),
   cancel_recommendation (bool), estimated_annual_savings (float),
   confidence (float 0-1)."""

def screen_benefits_eligibility(
    program: str,
    state: str,
    estimated_monthly_income: float,
    estimated_assets: float,
    has_medicare: bool,
    has_medicaid: bool,
    age: int
) -> dict by llm(model=llm);
sem screen_benefits_eligibility = """Screen a Medicare beneficiary for eligibility in an assistance program.
   Programs include: EXTRA_HELP (Part D Low Income Subsidy), QMB (Qualified
   Medicare Beneficiary), SLMB (Specified Low-Income Medicare Beneficiary),
   SNAP (food assistance), LIHEAP (energy assistance), MEDICARE_SAVINGS_PROGRAM,
   STATE_PHARMACEUTICAL_ASSISTANCE.
   Use 2026 federal poverty level thresholds. Consider state-specific rules where known.
   Return dict with: is_eligible (bool), confidence (float 0-1),
   program_name (str), reason (str, brief explanation of eligibility determination),
   monthly_savings (float, estimated monthly savings if enrolled),
   application_url (str, official program application URL if known),
   application_phone (str, phone number to apply if known)."""

# ═══════════════════════════════════════════════════════════════
# ADDENDUM v2 — Appointments, Prescriptions, Records, Bills, Benefits
# ═══════════════════════════════════════════════════════════════

def extract_appointment_from_email(
    email_text: str
) -> dict by llm(model=llm);
sem extract_appointment_from_email = """Extract appointment details from an email or document.
   Return dict with: found (bool), date (str YYYY-MM-DD), time (str HH:MM),
   provider (str), facility (str), specialty (str), purpose (str),
   address (str), phone (str), confirmation_number (str).
   Use empty string for any field not found."""

def detect_care_gaps(
    specialties_seen: list,
    last_visit_map: dict,
    patient_age: int,
    today: str
) -> list by llm(model=llm);
sem detect_care_gaps = """Identify gaps in preventive and routine care for an elderly Medicare patient.
   Based on the specialties visited and last visit dates, identify missing or overdue care.
   For each gap return a dict with: gap_type (str), last_visit_date (str),
   interval_days (int, recommended frequency), days_overdue (int), severity (LOW|MEDIUM|HIGH|CRITICAL),
   action (str, recommended action), specialty (str).
   Use CMS preventive care guidelines and USPSTF recommendations for patients 65+."""

def identify_medication_from_code(
    code: str,
    description: str
) -> dict by llm(model=llm);
sem identify_medication_from_code = """Identify a medication from a CPT/HCPCS code and description.
   Return dict with: drug_name (str), generic_name (str), ndc (str),
   therapeutic_class (str), active_ingredient (str), found (bool).
   Use empty string for unknown fields."""

def check_drug_interactions_detailed(
    medications: list
) -> dict by llm(model=llm);
sem check_drug_interactions_detailed = """Check for clinically significant drug interactions among a list of medications.
   Return dict with: interactions (list of dicts, each with: drug_a, drug_b,
   severity (MINIMAL|MINOR|MODERATE|MAJOR|CONTRAINDICATED), description, clinical_management).
   Focus on interactions relevant to elderly patients with common Medicare diagnoses.
   Only return interactions of MODERATE severity or higher."""

def check_formulary_coverage(
    drug_name: str,
    ndc: str,
    plan_type: str
) -> dict by llm(model=llm);
sem check_formulary_coverage = """Check if a medication is covered under a Medicare Part D formulary.
   Return dict with: covered (bool), tier (int 1-5), tier_changed (bool),
   not_covered (bool), requires_prior_auth (bool), step_therapy_required (bool),
   message (str, plain-English explanation of coverage status),
   alternatives (list of str, generic or lower-tier alternatives if applicable)."""

def extract_pharmacy_notification(
    email_text: str
) -> dict by llm(model=llm);
sem extract_pharmacy_notification = """Extract pharmacy notification details from an email.
   Return dict with: drug_name (str), action (str: READY_FOR_PICKUP|REFILL_REMINDER|SHIPPED|DELAYED),
   pickup_date (str), tracking_number (str), pharmacy_name (str), found (bool)."""

def assess_records_transfer_need(
    specialty: str,
    purpose: str,
    existing_transfers: list
) -> dict by llm(model=llm);
sem assess_records_transfer_need = """Assess whether a medical records transfer is needed for an upcoming specialist appointment.
   Based on the specialist type and visit purpose, determine if records from another provider
   are typically required. Return dict with: transfer_needed (bool), record_types (list of str),
   reason (str, why these records are needed), urgency (LOW|MEDIUM|HIGH)."""

def generate_hipaa_auth_form(
    patient_name: str,
    patient_dob: str,
    patient_address: str,
    purpose: str,
    sending_provider: str,
    receiving_provider: str,
    authorization_date: str
) -> dict by llm(model=llm);
sem generate_hipaa_auth_form = """Generate a pre-filled HIPAA authorization form (IHS-810 compatible format).
   Return dict with: form_text (str, complete form text ready for signature),
   expiry_date (str, 1 year from authorization_date).
   Include all required HIPAA elements: patient identification, description of
   information to be disclosed, purpose of disclosure, expiration, right to revoke,
   signature line. Add clear 'SIGNATURE REQUIRED' placeholder."""

def classify_subscription_v2(
    service_name: str,
    monthly_cost: float,
    usage_evidence: str,
    patient_age: int
) -> dict by llm(model=llm);
sem classify_subscription_v2 = """Classify a recurring subscription charge for an elderly Medicare patient.
   Return dict with: classification (ESSENTIAL|USEFUL|WASTEFUL), confidence (float 0-1),
   usage_notes (str, reasoning about whether the service is being used),
   recommendation (str, brief recommendation about keeping or canceling).
   ESSENTIAL: utilities, insurance, phone, internet, medical services.
   USEFUL: services with clear value to the patient.
   WASTEFUL: duplicate services, clearly unused, or inappropriate for patient's situation."""

def generate_subscription_audit_summary(
    patient_name: str,
    subscriptions: list,
    potential_savings: float
) -> dict by llm(model=llm);
sem generate_subscription_audit_summary = """Generate a plain-English subscription audit report for an elderly patient and their caregiver.
   Return dict with: text (str, 2-3 paragraph summary of findings),
   top_cancellation_recommendations (list of str, top 3 subscriptions to cancel and why).
   Keep language simple. Frame savings in annual terms. Note any essential services to keep."""

def generate_benefits_summary(
    patient_name: str,
    eligible_programs: list,
    total_monthly_savings: float
) -> dict by llm(model=llm);
sem generate_benefits_summary = """Generate a plain-English summary of government benefit programs a patient may qualify for.
   Return dict with: text (str, clear explanation of findings and recommended next steps),
   priority_programs (list of str, most valuable/easiest programs to apply for first).
   Explain each program in simple terms. Emphasize the financial impact."""

def prefill_benefit_application(
    program: str,
    patient_name: str,
    patient_dob: str,
    patient_address: str,
    patient_state: str,
    medicare_id: str
) -> dict by llm(model=llm);
sem prefill_benefit_application = """Pre-fill a benefit program application form with patient information.
   Return dict with: form_content (str, filled application with patient data),
   missing_fields (list of str, fields the patient still needs to fill in),
   submission_instructions (str, where and how to submit).
   Add clear labels for fields still needing patient input: [PATIENT TO COMPLETE]."""

def generate_negotiation_strategy(
    dispute_type: str,
    amount_disputed: float,
    appeal_level: int,
    error_description: str,
    payer_name: str
) -> dict by llm(model=llm);
sem generate_negotiation_strategy = """Generate a phone negotiation strategy for resolving a Medicare billing dispute.
   Return dict with: opening_statement (str), key_arguments (list of str),
   regulatory_citations (list of str, specific CMS rules to cite),
   fallback_positions (list of str), escalation_triggers (list of str),
   likely_objections (list of dicts with objection and counter_argument)."""
