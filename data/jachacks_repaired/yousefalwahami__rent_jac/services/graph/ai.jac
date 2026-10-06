"""AI functions: LLM return types, semantic annotations, and by llm() calls."""

import from services.graph.models { EventType }


# ── LLM Return Types ────────────────────────────────────────

obj MaintenanceDiagnosis {
    has category: str;
    has summary: str;
    has urgency: str;
    has recommended_action: str;
}

sem MaintenanceDiagnosis.category = "One of: hvac, plumbing, electrical, appliance, general";
sem MaintenanceDiagnosis.summary = "Brief 1-2 sentence diagnosis of the maintenance issue";
sem MaintenanceDiagnosis.urgency = "One of: low, medium, high, critical";
sem MaintenanceDiagnosis.recommended_action = "Specific recommended next step to resolve the issue";

obj RiskAssessment {
    has level: str;
    has flags: str;
    has recommendation: str;
}

sem RiskAssessment.level = "One of: low, moderate, high";
sem RiskAssessment.flags = "Comma-separated risk factors (e.g. repeat_incident, safety_hazard, property_damage)";
sem RiskAssessment.recommendation = "Brief recommendation considering the risk factors";


# ── LLM Functions ────────────────────────────────────────────

sem classify_event = "Classify a tenant's inbound message into the appropriate event type based on content and intent.";
def classify_event(message: str) -> EventType by llm();

sem diagnose_issue = "Diagnose a maintenance issue from a tenant message. Determine the repair category, severity, and what action to take. Consider safety implications.";
def diagnose_issue(message: str) -> MaintenanceDiagnosis by llm();

sem select_vendor = "Given a maintenance diagnosis and a list of available vendors with their specialties, ratings, and costs, return ONLY the name of the single best vendor for this job.";
def select_vendor(diagnosis: str, available_vendors: str) -> str by llm();

sem assess_risk = "Assess the risk level of a maintenance situation. Consider: repeat incidents on the same unit, tenant payment status, safety hazards, potential property damage.";
def assess_risk(context: str) -> RiskAssessment by llm();

sem draft_tenant_reply = "Draft a brief, professional SMS reply to a tenant who reported a maintenance issue. Acknowledge the problem, give safety advice if needed, and set expectations. Keep under 160 characters.";
def draft_tenant_reply(context: str) -> str by llm();

sem draft_owner_alert = "Draft a concise SMS alert for the property owner about a new maintenance issue. Include unit, issue type, urgency, and recommended vendor with cost. Keep under 200 characters.";
def draft_owner_alert(context: str) -> str by llm();
