"""
MedGraph AI — Agentic Personal Health Navigator
Built with Jac for JacHacks Spring 2026
Track: Consumer Healthcare
"""

import from os { environ }
import from byllm.lib { Model }

glob demo_mode = environ.get("MEDGRAPH_DEMO", "1") == "1";
glob llm = Model(
    model_name=environ.get("BYLLM_MODEL", "groq/llama-3.3-70b-versatile"),
    api_key=environ.get("GROQ_API_KEY", environ.get("FEATHERLESS_API_KEY", ""))
);

# ============================================================
# GRAPH NODES
# ============================================================

node Patient {
    has name: str;
    has age: int;
    has gender: str;
    has blood_type: str = "Unknown";
    has allergies: list[str] = [];
    has is_active: bool = True;
}

node Condition {
    has name: str;
    has severity: str = "moderate";
    has diagnosed_date: str = "";
    has is_active: bool = True;
    has notes: str = "";
}

node Medication {
    has name: str;
    has dosage: str;
    has frequency: str;
    has prescriber: str = "";
    has purpose: str = "";
}

node LabResult {
    has test_name: str;
    has value: str;
    has unit: str = "";
    has date: str = "";
    has reference_range: str = "";
    has is_abnormal: bool = False;
}

node CareGap {
    has screening_name: str;
    has priority: str = "routine";
    has reasoning: str = "";
}

node HealthInsight {
    has category: str;
    has title: str;
    has description: str;
    has recommendation: str;
}

# ============================================================
# AI TYPES & by llm() FUNCTIONS
# ============================================================

obj TriageResult {
    has urgency: str;
    has possible_conditions: list[str];
    has recommended_actions: list[str];
    has should_see_doctor: bool;
    has reasoning: str;
}
sem TriageResult = "Medical triage assessment result";

obj InteractionResult {
    has risk: str;
    has mechanism: str;
    has clinical_effect: str;
    has recommendation: str;
}
sem InteractionResult = "Drug-drug interaction analysis";

obj CareGapResult {
    has screening_name: str;
    has priority: str;
    has reasoning: str;
}
sem CareGapResult = "A preventive care screening gap";

obj LabInterpretation {
    has status: str;
    has clinical_significance: str;
    has follow_up_needed: bool;
    has patient_explanation: str;
}
sem LabInterpretation = "Interpretation of a laboratory test result";

obj RiskAssessment {
    has overall_risk: str;
    has risk_factors: list[str];
    has protective_factors: list[str];
    has recommendations: list[str];
    has ten_year_outlook: str;
}
sem RiskAssessment = "Comprehensive health risk assessment";

def triage_symptoms(
    symptoms: list[str],
    patient_age: int,
    patient_gender: str,
    existing_conditions: list[str],
    current_medications: list[str]
) -> TriageResult by llm(temperature=0.2);
sem triage_symptoms = "Perform medical symptom triage using patient graph context.";

def analyze_drug_interaction(
    drug_a: str,
    drug_a_dosage: str,
    drug_b: str,
    drug_b_dosage: str,
    patient_conditions: list[str]
) -> InteractionResult by llm(temperature=0.1);
sem analyze_drug_interaction = "Analyze potential drug-drug interaction.";

def identify_care_gaps(
    patient_age: int,
    patient_gender: str,
    existing_conditions: list[str],
    recent_screenings: list[str]
) -> list[CareGapResult] by llm(temperature=0.2);
sem identify_care_gaps = "Identify preventive care gaps per USPSTF guidelines.";

def interpret_lab_result(
    test_name: str,
    value: str,
    unit: str,
    reference_range: str,
    patient_age: int,
    patient_conditions: list[str]
) -> LabInterpretation by llm(temperature=0.1);
sem interpret_lab_result = "Interpret a lab result for the patient.";

def generate_health_summary(
    patient_name: str,
    patient_age: int,
    conditions: list[str],
    medications: list[str],
    recent_labs: list[str],
    care_gaps: list[str]
) -> str by llm(temperature=0.3);
sem generate_health_summary = "Patient-friendly health summary.";

def assess_health_risk(
    patient_age: int,
    patient_gender: str,
    conditions: list[str],
    medications: list[str],
    lab_results: list[str]
) -> RiskAssessment by llm(temperature=0.2);
sem assess_health_risk = "Comprehensive health risk assessment with 10-year outlook.";

# ============================================================
# DEMO FALLBACKS (stable hackathon demo without API keys)
# ============================================================

def demo_triage(symptoms: list[str]) -> TriageResult {
    return TriageResult(
        urgency="MODERATE",
        possible_conditions=["Uncontrolled hypertension", "Medication side effect"],
        recommended_actions=[
            "Check blood pressure twice daily for 3 days",
            "Contact primary care within 48 hours",
            "Seek ER care if chest pain or severe shortness of breath"
        ],
        should_see_doctor=True,
        reasoning=f"Symptoms ({', '.join(symptoms)}) in a 62-year-old with diabetes and hypertension warrant clinician review."
    );
}

def demo_interaction(drug_a: str, drug_b: str) -> InteractionResult {
    pair = {drug_a, drug_b};
    if "Lisinopril" in pair and "Amlodipine" in pair {
        return InteractionResult(
            risk="MODERATE",
            mechanism="Dual RAAS/calcium-channel pathways increase hypotension risk",
            clinical_effect="Dizziness, lightheadedness, especially on standing",
            recommendation="Monitor BP at home; discuss dose timing with prescriber"
        );
    }
    if "Metformin" in pair and "Lisinopril" in pair {
        return InteractionResult(
            risk="MILD",
            mechanism="Additive glucose-lowering with ACE inhibitor context",
            clinical_effect="Possible hypoglycemia symptoms if glycemic control shifts",
            recommendation="Monitor fasting glucose; report shakiness or sweating"
        );
    }
    return InteractionResult(risk="NONE", mechanism="No significant interaction", clinical_effect="None expected", recommendation="Continue as prescribed");
}

def demo_care_gaps() -> list[CareGapResult] {
    return [
        CareGapResult(
            screening_name="Bone Density Scan (DEXA)",
            priority="OVERDUE",
            reasoning="Female age 62 with osteopenia — repeat DEXA per guideline interval"
        ),
        CareGapResult(
            screening_name="Diabetic Eye Exam",
            priority="RECOMMENDED",
            reasoning="Type 2 diabetes — annual retinal screening due"
        )
    ];
}

def demo_lab(test_name: str, value: str, unit: str) -> LabInterpretation {
    if test_name == "HbA1c" {
        return LabInterpretation(
            status="ABNORMAL",
            clinical_significance="Glycemic control above target for diabetes",
            follow_up_needed=True,
            patient_explanation="Your average blood sugar has been higher than goal; medication or lifestyle adjustment may help."
        );
    }
    if test_name == "Vitamin D" {
        return LabInterpretation(
            status="DEFICIENT",
            clinical_significance="Low vitamin D worsens bone health and fatigue",
            follow_up_needed=True,
            patient_explanation="Your vitamin D is low; supplementation and recheck in 8–12 weeks is typical."
        );
    }
    return LabInterpretation(
        status="NORMAL",
        clinical_significance="Within expected range",
        follow_up_needed=False,
        patient_explanation="No immediate action needed for this test."
    );
}

def demo_risk() -> RiskAssessment {
    return RiskAssessment(
        overall_risk="HIGH",
        risk_factors=[
            "Uncontrolled Type 2 Diabetes (HbA1c 7.8%)",
            "Stage 2 Hypertension (148/94)",
            "Elevated LDL (158 mg/dL)",
            "Vitamin D deficiency"
        ],
        protective_factors=[
            "Active medication adherence",
            "No smoking reported",
            "Regular primary care engagement"
        ],
        recommendations=[
            "Intensify diabetes management with endocrinology follow-up",
            "Add or optimize statin therapy for LDL",
            "Schedule overdue DEXA scan",
            "Start vitamin D repletion protocol"
        ],
        ten_year_outlook="Elevated cardiovascular and fracture risk without tighter metabolic and bone-health control; preventable with coordinated care."
    );
}

def demo_summary_for_patient(pname: str, conditions: list[str], med_count: int, lab_count: int) -> str {
    cs = ", ".join(conditions.slice(0, 5)) if len(conditions) else "no conditions listed";
    return (
        f"{pname} — graph snapshot: {cs}. "
        f"Active medications: {med_count}. Recent labs on file: {lab_count}. "
        f"Demo mode (MEDGRAPH_DEMO=1) uses scripted walker outputs; set MEDGRAPH_DEMO=0 and configure an API key for live LLM reasoning."
    );
}

# ============================================================
# GRAPH BUILD & HELPERS
# ============================================================

def build_sarah_graph() -> Patient {
    patient = Patient(
        name="Sarah Chen",
        age=62,
        gender="female",
        blood_type="A+",
        allergies=["Penicillin", "Sulfa drugs"]
    );
    patient ++> Condition(name="Hypertension (Stage 2)", severity="moderate", diagnosed_date="2019-03-15");
    patient ++> Condition(name="Type 2 Diabetes", severity="moderate", diagnosed_date="2021-08-22");
    patient ++> Condition(name="Generalized Anxiety Disorder", severity="mild", diagnosed_date="2020-01-10");
    patient ++> Condition(name="Osteopenia", severity="mild", diagnosed_date="2023-06-01", notes="T-score -1.8");
    patient ++> Medication(name="Lisinopril", dosage="20mg", frequency="Once daily", prescriber="Dr. Patel");
    patient ++> Medication(name="Metformin", dosage="1000mg", frequency="Twice daily", prescriber="Dr. Patel");
    patient ++> Medication(name="Sertraline", dosage="50mg", frequency="Once daily", prescriber="Dr. Kim");
    patient ++> Medication(name="Amlodipine", dosage="5mg", frequency="Once daily", prescriber="Dr. Patel");
    patient ++> Medication(name="Calcium + Vitamin D", dosage="600mg/400IU", frequency="Twice daily", prescriber="Dr. Singh");
    patient ++> LabResult(test_name="HbA1c", value="7.8", unit="%", reference_range="< 7.0%", is_abnormal=True);
    patient ++> LabResult(test_name="Blood Pressure", value="148/94", unit="mmHg", reference_range="< 130/80", is_abnormal=True);
    patient ++> LabResult(test_name="Fasting Glucose", value="156", unit="mg/dL", reference_range="70-100", is_abnormal=True);
    patient ++> LabResult(test_name="Total Cholesterol", value="242", unit="mg/dL", reference_range="< 200", is_abnormal=True);
    patient ++> LabResult(test_name="LDL Cholesterol", value="158", unit="mg/dL", reference_range="< 100", is_abnormal=True);
    patient ++> LabResult(test_name="eGFR", value="72", unit="mL/min", reference_range="> 90");
    patient ++> LabResult(test_name="Vitamin D", value="22", unit="ng/mL", reference_range="30-100", is_abnormal=True);
    return patient;
}

walker FindPatient {
    has patient: object = None;

    can find with Root entry {
        self.patient = None;
        for node in [-->] {
            if node is Patient {
                if node.is_active {
                    self.patient = node;
                    break;
                }
            }
        }
        if self.patient is None {
            for node in [-->] {
                if node is Patient {
                    self.patient = node;
                    break;
                }
            }
        }
    }
}

def get_patient() -> object {
    finder = FindPatient() spawn root;
    return finder.patient;
}

# Deactivate all patients linked from root (used before replacing profile).
walker DeactivatePatientsWalker {
    can sweep with Root entry {
        visit [-->];
    }

    can off with Patient entry {
        here.is_active = False;
    }
}

def deactivate_all_patients() -> None {
    DeactivatePatientsWalker() spawn root;
}

def snapshot_from_patient(patient: Patient) -> dict {
    collector = DataCollector() spawn patient;
    nodes = [{"id": "patient", "label": patient.name, "type": "patient"}];
    edges = [];
    idx = 2;
    for cname in collector.conditions {
        nid = f"cond_{idx}";
        nodes.append({"id": nid, "label": cname, "type": "condition"});
        edges.append({"from": "patient", "to": nid, "label": "has_condition"});
        idx += 1;
    }
    for med in collector.med_objects {
        nid = f"med_{idx}";
        nodes.append({"id": nid, "label": f"{med.name}\n({med.dosage})", "type": "medication"});
        edges.append({"from": "patient", "to": nid, "label": "takes_med"});
        idx += 1;
    }
    for lab in collector.lab_objects {
        nid = f"lab_{idx}";
        nodes.append({
            "id": nid,
            "label": f"{lab.test_name}\n({lab.value} {lab.unit})",
            "type": "lab",
            "abnormal": lab.is_abnormal
        });
        edges.append({"from": "patient", "to": nid, "label": "has_lab"});
        idx += 1;
    }
    return {
        "patient": {
            "name": patient.name,
            "age": patient.age,
            "gender": patient.gender,
            "blood_type": patient.blood_type,
            "allergies": patient.allergies
        },
        "counts": {
            "conditions": len(collector.conditions),
            "medications": len(collector.medications),
            "labs": len(collector.labs)
        },
        "graph": {"nodes": nodes, "edges": edges}
    };
}

# ============================================================
# WALKERS (agents)
# ============================================================

walker DataCollector {
    has conditions: list[str] = [];
    has medications: list[str] = [];
    has med_objects: list[Medication] = [];
    has labs: list[str] = [];
    has lab_objects: list[LabResult] = [];
    has patient_name: str = "";
    has patient_age: int = 0;
    has patient_gender: str = "";

    can on_patient with Patient entry {
        self.patient_name = here.name;
        self.patient_age = here.age;
        self.patient_gender = here.gender;
        visit [-->];
    }

    can on_condition with Condition entry {
        self.conditions.append(here.name);
    }

    can on_medication with Medication entry {
        self.medications.append(f"{here.name} ({here.dosage})");
        self.med_objects.append(here);
    }

    can on_lab with LabResult entry {
        self.labs.append(f"{here.test_name}: {here.value} {here.unit}");
        self.lab_objects.append(here);
    }
}

walker SymptomTriageWalker {
    has symptoms: list[str] = [];
    has triage_result: dict = {};

    can triage with Patient entry {
        collector = DataCollector() spawn here;
        if demo_mode {
            result = demo_triage(self.symptoms);
        } else {
            result = triage_symptoms(
                self.symptoms,
                collector.patient_age,
                collector.patient_gender,
                collector.conditions,
                collector.medications
            );
        }
        self.triage_result = {
            "urgency": result.urgency,
            "possible_conditions": result.possible_conditions,
            "recommended_actions": result.recommended_actions,
            "should_see_doctor": result.should_see_doctor,
            "reasoning": result.reasoning
        };
        here ++> HealthInsight(
            category="triage",
            title=f"Symptom Triage: {', '.join(self.symptoms)}",
            description=result.reasoning,
            recommendation="; ".join(result.recommended_actions)
        );
    }
}

walker DrugInteractionWalker {
    has interactions_found: list[dict] = [];

    can scan with Patient entry {
        collector = DataCollector() spawn here;
        meds = collector.med_objects;
        for i in range(len(meds)) {
            for j in range(i + 1, len(meds)) {
                med_a = meds[i];
                med_b = meds[j];
                if demo_mode {
                    interaction = demo_interaction(med_a.name, med_b.name);
                } else {
                    interaction = analyze_drug_interaction(
                        med_a.name, med_a.dosage, med_b.name, med_b.dosage, collector.conditions
                    );
                }
                if interaction.risk != "NONE" {
                    self.interactions_found.append({
                        "drug_a": med_a.name,
                        "drug_b": med_b.name,
                        "risk": interaction.risk,
                        "mechanism": interaction.mechanism,
                        "effect": interaction.clinical_effect,
                        "recommendation": interaction.recommendation
                    });
                    here ++> HealthInsight(
                        category="drug_interaction",
                        title=f"{med_a.name} + {med_b.name}: {interaction.risk}",
                        description=interaction.clinical_effect,
                        recommendation=interaction.recommendation
                    );
                }
            }
        }
    }
}

walker PreventiveCareWalker {
    has care_gaps_found: list[dict] = [];

    can find_gaps with Patient entry {
        collector = DataCollector() spawn here;
        if demo_mode {
            gaps = demo_care_gaps();
        } else {
            gaps = identify_care_gaps(
                collector.patient_age,
                collector.patient_gender,
                collector.conditions,
                collector.labs
            );
        }
        for gap in gaps {
            here ++> CareGap(
                screening_name=gap.screening_name,
                priority=gap.priority,
                reasoning=gap.reasoning
            );
            self.care_gaps_found.append({
                "screening": gap.screening_name,
                "priority": gap.priority,
                "reasoning": gap.reasoning
            });
        }
    }
}

walker LabAnalyzerWalker {
    has interpretations: list[dict] = [];

    can analyze with Patient entry {
        collector = DataCollector() spawn here;
        for lab in collector.lab_objects {
            if demo_mode {
                interp = demo_lab(lab.test_name, lab.value, lab.unit);
            } else {
                interp = interpret_lab_result(
                    lab.test_name, lab.value, lab.unit, lab.reference_range,
                    collector.patient_age, collector.conditions
                );
            }
            self.interpretations.append({
                "test": lab.test_name,
                "value": f"{lab.value} {lab.unit}",
                "status": interp.status,
                "significance": interp.clinical_significance,
                "follow_up": interp.follow_up_needed,
                "explanation": interp.patient_explanation
            });
            if interp.follow_up_needed {
                here ++> HealthInsight(
                    category="lab_alert",
                    title=f"Lab Alert: {lab.test_name} = {lab.value} {lab.unit}",
                    description=interp.clinical_significance,
                    recommendation=interp.patient_explanation
                );
            }
        }
    }
}

walker CareCoordinatorWalker {
    has full_report: dict = {};

    can coordinate with Patient entry {
        collector = DataCollector() spawn here;
        drug_w = DrugInteractionWalker() spawn here;
        care_w = PreventiveCareWalker() spawn here;
        lab_w = LabAnalyzerWalker() spawn here;

        if demo_mode {
            risk = demo_risk();
            summary = demo_summary_for_patient(
                here.name,
                collector.conditions,
                len(collector.med_objects),
                len(collector.lab_objects)
            );
        } else {
            risk = assess_health_risk(
                collector.patient_age,
                collector.patient_gender,
                collector.conditions,
                collector.medications,
                collector.labs
            );
            care_gap_names: list[str] = [];
            for gap_node in [-->] {
                if gap_node is CareGap {
                    care_gap_names.append(str(gap_node.screening_name));
                }
            }
            summary = generate_health_summary(
                here.name, here.age, collector.conditions,
                collector.medications, collector.labs, care_gap_names
            );
        }

        insights: list[dict] = [];
        for node in [-->] {
            if node is HealthInsight {
                insights.append({
                    "category": node.category,
                    "title": node.title,
                    "description": node.description,
                    "recommendation": node.recommendation
                });
            }
        }

        self.full_report = {
            "patient": here.name,
            "risk": risk.overall_risk,
            "summary": summary,
            "risk_factors": risk.risk_factors,
            "protective_factors": risk.protective_factors,
            "recommendations": risk.recommendations,
            "ten_year_outlook": risk.ten_year_outlook,
            "interactions": drug_w.interactions_found,
            "care_gaps": care_w.care_gaps_found,
            "labs": lab_w.interpretations,
            "insights": insights,
            "demo_mode": demo_mode
        };
    }
}

# ============================================================
# PUBLIC API WALKERS (jac start → REST)
# ============================================================

walker:pub health {
    can check with Root entry {
        report {
            "status": "ok",
            "service": "MedGraph AI",
            "demo_mode": demo_mode
        };
    }
}

walker:pub ensure_graph {
    can init with Root entry {
        patient = get_patient();
        if patient is None {
            patient = build_sarah_graph();
            root ++> patient;
        }
        report snapshot_from_patient(patient);
    }
}

walker:pub get_snapshot {
    can fetch with Root entry {
        patient = get_patient();
        if patient is None {
            patient = build_sarah_graph();
            root ++> patient;
        }
        report snapshot_from_patient(patient);
    }
}

walker:pub run_analysis {
    can run with Root entry {
        patient = get_patient();
        if patient is None {
            patient = build_sarah_graph();
            root ++> patient;
        }
        coordinator = CareCoordinatorWalker() spawn patient;
        report coordinator.full_report;
    }
}

walker:pub run_triage {
    has symptoms: list[str] = [];

    can triage with Root entry {
        patient = get_patient();
        if patient is None {
            patient = build_sarah_graph();
            root ++> patient;
        }
        triage_w = SymptomTriageWalker(symptoms=self.symptoms) spawn patient;
        report triage_w.triage_result;
    }
}

walker:pub rebuild_patient_from_profile {
    has name: str;
    has age: int;
    has gender: str;
    has blood_type: str = "Unknown";
    has allergies: list[str] = [];
    has conditions: list[str] = [];
    has med_names: list[str] = [];
    has med_dosages: list[str] = [];
    has med_frequencies: list[str] = [];
    has lab_tests: list[str] = [];
    has lab_values: list[str] = [];
    has lab_units: list[str] = [];
    has lab_refs: list[str] = [];
    has lab_abnormal_flags: list[bool] = [];

    can rebuild with Root entry {
        deactivate_all_patients();
        patient = Patient(
            name=self.name,
            age=self.age,
            gender=self.gender,
            blood_type=self.blood_type,
            allergies=self.allergies,
            is_active=True
        );
        for cname in self.conditions {
            if cname {
                patient ++> Condition(name=cname);
            }
        }
        for i in range(len(self.med_names)) {
            n = self.med_names[i];
            if n {
                dose = self.med_dosages[i] if i < len(self.med_dosages) else "";
                freq = self.med_frequencies[i] if i < len(self.med_frequencies) else "As directed";
                patient ++> Medication(name=n, dosage=dose, frequency=freq);
            }
        }
        for i in range(len(self.lab_tests)) {
            t = self.lab_tests[i];
            if t {
                val = self.lab_values[i] if i < len(self.lab_values) else "";
                unit = self.lab_units[i] if i < len(self.lab_units) else "";
                ref = self.lab_refs[i] if i < len(self.lab_refs) else "";
                abn = False;
                if i < len(self.lab_abnormal_flags) {
                    abn = self.lab_abnormal_flags[i];
                }
                patient ++> LabResult(test_name=t, value=val, unit=unit, reference_range=ref, is_abnormal=abn);
            }
        }
        root ++> patient;
        report snapshot_from_patient(patient);
    }
}

walker:pub reset_demo {
    can run with Root entry {
        deactivate_all_patients();
        patient = build_sarah_graph();
        root ++> patient;
        report snapshot_from_patient(patient);
    }
}

# ============================================================
# CLI ENTRY — graph only (no LLM on import)
# ============================================================

with entry {
    print("\n╔══════════════════════════════════════════════════════════╗");
    print("║          MedGraph AI — Agentic Health Navigator         ║");
    print("║     JacHacks Spring 2026 | Consumer Healthcare          ║");
    print("╚══════════════════════════════════════════════════════════╝\n");

    if environ.get("RUN_ANALYSIS", "") == "1" {
        print("🤖 Running CareCoordinatorWalker...\n");
        patient = build_sarah_graph();
        root ++> patient;
        CareCoordinatorWalker() spawn patient;
        print("\n✅ Analysis complete.\n");
    } else {
        print("💡 Full stack:     ./start.sh");
        print("💡 API only:       jac start main.jac --port 8000 --no_client");
        print("💡 CLI analysis:   RUN_ANALYSIS=1 jac run main.jac");
        print(f"💡 Demo mode:      MEDGRAPH_DEMO={demo_mode}\n");
    }
}
