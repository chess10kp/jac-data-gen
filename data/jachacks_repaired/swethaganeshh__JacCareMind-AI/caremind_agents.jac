# CareMind AI - Jac Agent Orchestration
# Autonomous Healthcare AI Assistant for Elderly Care
# Uses Jac's graph nodes, walkers, and by llm() syntax

import from jaclang.plugin.feature { JacFeature as Jac }
import json;
import os;
import from byllm.lib { Model }

glob llm: Model = Model(model_name="meta-llama/Llama-3.3-70B-Instruct");

# ─────────────────────────────────────────────
# DATA MODELS
# ─────────────────────────────────────────────

obj PatientContext {
    has patient_id: str;
    has name: str;
    has age: int;
    has conditions: list;
    has medications: list;
    has allergies: list;
    has recent_history: str;
    has message: str;
}

obj AgentResult {
    has agent_name: str;
    has output: dict;
    has success: bool;
}

# ─────────────────────────────────────────────
# GRAPH NODES (Agent Nodes)
# ─────────────────────────────────────────────

node MemoryNode {
    has patient_data: dict = {};
    has memory_context: dict = {};

    def retrieve_context(ctx: PatientContext) -> dict
        by llm(temperature = 0.2, max_tokens = 600);
}
sem MemoryNode.retrieve_context = """
You are the CareMind Memory Agent.

Patient Record: {ctx.patient_data}
Current Message: "{ctx.message}"

Extract and return JSON with:
{
  "relevant_conditions": ["conditions relevant to current message"],
  "relevant_medications": ["medications that may relate"],
  "recent_history_summary": "2-3 sentence summary",
  "known_allergies": ["list"],
  "risk_factors": ["pre-existing elevating factors"],
  "context_notes": "important context for other agents"
}
Return ONLY valid JSON, no other text.
""";

node SymptomNode {
    has memory_context: dict = {};
    has symptom_analysis: dict = {};

    def analyze_symptoms(ctx: PatientContext, memory: dict) -> dict
        by llm(temperature = 0.3, max_tokens = 800);
}
sem SymptomNode.analyze_symptoms = """
You are the CareMind Symptom Analysis Agent.

Patient Age: {ctx.age}
Patient Conditions: {memory["relevant_conditions"]}
Current Medications: {memory["relevant_medications"]}
Risk Factors: {memory["risk_factors"]}

Patient Reports: "{ctx.message}"

Return JSON:
{
  "identified_symptoms": ["specific symptoms"],
  "possible_causes": [{"cause": "name", "likelihood": "high/medium/low", "reasoning": "brief"}],
  "red_flag_symptoms": ["alarming symptoms"],
  "follow_up_questions": ["Q1?", "Q2?", "Q3?"],
  "severity_assessment": "mild/moderate/severe/critical",
  "analysis_confidence": "high/medium/low"
}
Return ONLY valid JSON.
""";

node RiskNode {
    has symptom_analysis: dict = {};
    has risk_assessment: dict = {};

    def classify_risk(ctx: PatientContext, symptoms: dict, memory: dict) -> dict
        by llm(temperature = 0.1, max_tokens = 500);
}
sem RiskNode.classify_risk = """
You are the CareMind Risk Classification Agent.
Patient safety is the priority. When in doubt, escalate.

Patient Age: {ctx.age}
Identified Symptoms: {symptoms["identified_symptoms"]}
Red Flag Symptoms: {symptoms["red_flag_symptoms"]}
Severity: {symptoms["severity_assessment"]}
Pre-existing Conditions: {memory["relevant_conditions"]}
Risk Factors: {memory["risk_factors"]}

Classify risk and return JSON:
{
  "risk_level": "NONE|LOW|MEDIUM|HIGH|CRITICAL",
  "risk_score": 0-100,
  "primary_concern": "main concern",
  "contributing_factors": ["list"],
  "immediate_danger": true/false,
  "requires_911": true/false,
  "requires_urgent_care": true/false,
  "risk_reasoning": "2-3 sentence explanation",
  "time_sensitivity": "immediate/within-hours/within-day/monitor"
}
Return ONLY valid JSON.
""";

node PlanningNode {
    has risk_assessment: dict = {};
    has care_plan: dict = {};

    def generate_plan(ctx: PatientContext, risk: dict, symptoms: dict, memory: dict) -> dict
        by llm(temperature = 0.4, max_tokens = 800);
}
sem PlanningNode.generate_plan = """
You are the CareMind Planning Agent.
Create safe, actionable care plans for elderly patients.

Patient: {ctx.name}, Age {ctx.age}
Risk Level: {risk["risk_level"]}
Risk Score: {risk["risk_score"]}
Primary Concern: {risk["primary_concern"]}
Symptoms: {symptoms["identified_symptoms"]}
Known Allergies: {memory["known_allergies"]}
Requires 911: {risk["requires_911"]}

Return JSON:
{
  "immediate_actions": [{"action": "desc", "priority": "urgent/high/medium", "who": "patient/caregiver/911"}],
  "monitoring_instructions": ["watch for..."],
  "comfort_measures": ["safe self-care steps"],
  "medication_notes": "relevant guidance (no new Rx)",
  "when_to_escalate": ["signs to seek immediate help"],
  "follow_up": "timeline",
  "patient_message": "warm 2-3 sentence message to patient",
  "caregiver_summary": "brief clinical summary"
}
Return ONLY valid JSON.
""";

node AlertNode {
    has care_plan: dict = {};
    has alert_output: dict = {};

    def generate_alert(ctx: PatientContext, risk: dict, plan: dict, symptoms: dict) -> dict
        by llm(temperature = 0.2, max_tokens = 700);
}
sem AlertNode.generate_alert = """
You are the CareMind Caregiver Alert Agent.
Generate clear, urgent alerts for family caregivers.

Patient: {ctx.name}, Age {ctx.age}
Risk Level: {risk["risk_level"]}
Risk Score: {risk["risk_score"]}/100
Primary Concern: {risk["primary_concern"]}
Symptoms: {symptoms["identified_symptoms"]}
Red Flags: {symptoms["red_flag_symptoms"]}
Requires 911: {risk["requires_911"]}

Return JSON:
{
  "alert_generated": true,
  "alert_type": "risk level",
  "alert_title": "brief urgent title",
  "sms_message": "concise SMS under 160 chars",
  "email_subject": "email subject",
  "email_body": "full email with details and actions",
  "push_notification": "short push text",
  "recommended_response_time": "immediate/within-30-min/within-2-hours",
  "actions_for_caregiver": ["specific steps"],
  "patient_current_location_note": "check on patient"
}
Return ONLY valid JSON.
""";

# ─────────────────────────────────────────────
# GRAPH EDGES (Agent Pipeline Connections)
# ─────────────────────────────────────────────

edge MemoryToSymptom {}
edge SymptomToRisk {}
edge RiskToPlanning {}
edge PlanningToAlert {}

# ─────────────────────────────────────────────
# CAREMIND GRAPH (Agent Network)
# ─────────────────────────────────────────────

"""Create agent nodes, connect the pipeline, and return the entry node."""
def CareMindGraph() -> MemoryNode {
    entry_node = MemoryNode();
    symptom_node = SymptomNode();
    risk_node = RiskNode();
    planning_node = PlanningNode();
    alert_node = AlertNode();

    # Connect agent pipeline
    entry_node +>:MemoryToSymptom:+> symptom_node;
    symptom_node +>:SymptomToRisk:+> risk_node;
    risk_node +>:RiskToPlanning:+> planning_node;
    planning_node +>:PlanningToAlert:+> alert_node;

    return entry_node;
}

# ─────────────────────────────────────────────
# WALKER (Traverses Agent Graph)
# ─────────────────────────────────────────────

walker CareMindWalker {
    has patient_context: PatientContext;
    has results: dict = {};
    has pipeline_trace: list = [];

    # Entry point: Memory Node
    can visit_memory with MemoryNode entry {
        here.patient_data = {
            "patient_id": self.patient_context.patient_id,
            "name": self.patient_context.name,
            "age": self.patient_context.age,
            "conditions": self.patient_context.conditions,
            "medications": self.patient_context.medications,
            "allergies": self.patient_context.allergies,
            "recent_history": self.patient_context.recent_history,
            "message": self.patient_context.message
        };

        ctx = self.patient_context;
        memory_result = here.retrieve_context(ctx);

        here.memory_context = memory_result;
        self.results["memory"] = memory_result;
        self.pipeline_trace.append({
            "agent": "MemoryAgent",
            "node": "MemoryNode",
            "status": "complete"
        });

        # Traverse to next agent
        visit [-->];
    }

    # Symptom Analysis Node
    can visit_symptom with SymptomNode entry {
        memory = self.results.get("memory", {});
        ctx = self.patient_context;

        symptom_result = here.analyze_symptoms(ctx, memory);

        here.symptom_analysis = symptom_result;
        self.results["symptoms"] = symptom_result;
        self.pipeline_trace.append({
            "agent": "SymptomAnalysisAgent",
            "node": "SymptomNode",
            "status": "complete"
        });

        visit [-->];
    }

    # Risk Classification Node
    can visit_risk with RiskNode entry {
        symptoms = self.results.get("symptoms", {});
        memory = self.results.get("memory", {});
        ctx = self.patient_context;

        risk_result = here.classify_risk(ctx, symptoms, memory);

        # Add display metadata
        risk_colors = {
            "NONE": "#22c55e", "LOW": "#84cc16",
            "MEDIUM": "#f59e0b", "HIGH": "#ef4444", "CRITICAL": "#dc2626"
        };
        risk_level = risk_result.get("risk_level", "LOW");
        risk_result["display"] = {
            "color": risk_colors.get(risk_level, "#f59e0b"),
            "label": risk_level + " Risk"
        };

        here.risk_assessment = risk_result;
        self.results["risk"] = risk_result;
        self.pipeline_trace.append({
            "agent": "RiskClassificationAgent",
            "node": "RiskNode",
            "status": "complete"
        });

        visit [-->];
    }

    # Planning Node
    can visit_planning with PlanningNode entry {
        risk = self.results.get("risk", {});
        symptoms = self.results.get("symptoms", {});
        memory = self.results.get("memory", {});
        ctx = self.patient_context;

        plan_result = here.generate_plan(ctx, risk, symptoms, memory);

        here.care_plan = plan_result;
        self.results["plan"] = plan_result;
        self.pipeline_trace.append({
            "agent": "PlanningAgent",
            "node": "PlanningNode",
            "status": "complete"
        });

        visit [-->];
    }

    # Alert Node (terminal)
    can visit_alert with AlertNode entry {
        risk = self.results.get("risk", {});
        plan = self.results.get("plan", {});
        symptoms = self.results.get("symptoms", {});
        ctx = self.patient_context;

        # Only alert for MEDIUM+ risk
        if risk.get("risk_level") in ["MEDIUM", "HIGH", "CRITICAL"] {
            alert_result = here.generate_alert(ctx, risk, plan, symptoms);
        } else {
            alert_result = {
                "alert_generated": False,
                "reason": "Risk level below alert threshold"
            };
        }

        here.alert_output = alert_result;
        self.results["alert"] = alert_result;
        self.pipeline_trace.append({
            "agent": "CaregiverAlertAgent",
            "node": "AlertNode",
            "status": "complete"
        });

        # Walker complete - no more nodes
    }

    # Final result aggregation
    def get_final_output -> dict {
        plan = self.results.get("plan", {});
        return {
            "patient_id": self.patient_context.patient_id,
            "patient_name": self.patient_context.name,
            "pipeline_trace": self.pipeline_trace,
            "memory_context": self.results.get("memory", {}),
            "symptom_analysis": self.results.get("symptoms", {}),
            "risk_assessment": self.results.get("risk", {}),
            "care_plan": plan,
            "caregiver_alert": self.results.get("alert", {}),
            "response_to_patient": plan.get("patient_message", "I'm here to help you."),
            "follow_up_questions": self.results.get("symptoms", {}).get("follow_up_questions", [])
        };
    }
}

# ─────────────────────────────────────────────
# ENTRY POINT
# ─────────────────────────────────────────────

with entry {
    # Example usage
    print("CareMind AI - Jac Agent Network Initialized");
    print("Agents: MemoryNode → SymptomNode → RiskNode → PlanningNode → AlertNode");

    # To run the walker:
    # ctx = PatientContext(
    #     patient_id="P001",
    #     name="Margaret Thompson",
    #     age=78,
    #     conditions=["Type 2 Diabetes", "Hypertension"],
    #     medications=["Metformin", "Lisinopril"],
    #     allergies=["Penicillin"],
    #     recent_history="Recent dizziness episode",
    #     message="I have chest pain and feel short of breath"
    # );
    #
    # graph = spawn CareMindGraph();
    # walker = spawn CareMindWalker(patient_context=ctx);
    # walker spawn on graph.entry;
    # result = walker.get_final_output();
    # print(result);
}
