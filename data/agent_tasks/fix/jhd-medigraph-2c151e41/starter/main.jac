"""MediGraph — graph-native medication safety intelligence in Jac.

Models the body as a graph: Patients prescribe Drugs, Drugs are MetabolizedBy
Enzymes, Drugs Affect Organs. Walkers traverse this graph to detect drug
interactions by structural reasoning — two drugs sharing an enzyme where one
is an inhibitor is a conflict, regardless of any lookup table.
"""

import from datetime { datetime }
import from byllm.lib { Model }
import os;
import json;
import from dotenv { load_dotenv }
import from urllib.request { urlopen }
import from urllib.parse { quote }

with entry {
    load_dotenv();
}


# ---------------------------------------------------------------------------
# Node + edge types
# ---------------------------------------------------------------------------

node Patient {
    has name: str,
        age: int = 0,
        weight_kg: float = 70.0,
        kidney_function_gfr: float = 90.0,
        liver_function_score: float = 1.0;
}

node Drug {
    has name: str,
        generic_name: str = "",
        drug_class: str = "",
        dose_mg: float = 0.0,
        frequency: str = "",
        is_inhibitor: bool = False,
        is_inducer: bool = False,
        therapeutic_window: str = "wide",
        half_life_hours: float = 0.0;
}

node Enzyme {
    has name: str,
        organ: str = "liver",
        capacity: float = 1.0;
}

node Organ {
    has name: str,
        system: str = "",
        risk_score: float = 0.0;
}

node Registry {
    """Pinned-from-root flag so seed() is idempotent."""
    has seeded: bool = False;
}

edge MetabolizedBy {
    has primary: bool = True,
        percentage: float = 100.0;
}

edge AffectsOrgan {
    has mechanism: str = "",
        severity: str = "mild";
}

edge Prescribed {
    has start_date: str = "",
        prescriber: str = "MediGraph";
}

edge EnzymeIn {
    has dummy: bool = True;
}


# ---------------------------------------------------------------------------
# Typed drug metadata
# ---------------------------------------------------------------------------

obj OrganEffect {
    has organ: str;
    has mechanism: str;
    has severity: str;
}

obj DrugMeta {
    has name: str;
    has drug_class: str;
    has is_inhibitor: bool = False;
    has is_inducer: bool = False;
    has therapeutic_window: str = "wide";
    has half_life_hours: float = 0.0;
    has enzymes: list[str] = [];
    has organ_effects: list[OrganEffect] = [];
}


def build_drug_table -> list[DrugMeta] {
    return [
        DrugMeta(name="Warfarin", drug_class="anticoagulant",
            therapeutic_window="narrow", half_life_hours=40.0,
            enzymes=["CYP2C9"],
            organ_effects=[OrganEffect(organ="Liver", mechanism="bleeding risk", severity="severe")]),
        DrugMeta(name="Fluconazole", drug_class="antifungal", is_inhibitor=True,
            half_life_hours=30.0, enzymes=["CYP3A4", "CYP2C9"],
            organ_effects=[OrganEffect(organ="Liver", mechanism="hepatotoxicity", severity="moderate")]),
        DrugMeta(name="Clarithromycin", drug_class="macrolide antibiotic", is_inhibitor=True,
            half_life_hours=5.0, enzymes=["CYP3A4"],
            organ_effects=[
                OrganEffect(organ="Liver", mechanism="hepatotoxicity", severity="moderate"),
                OrganEffect(organ="Heart", mechanism="QT prolongation", severity="severe")
            ]),
        DrugMeta(name="Azithromycin", drug_class="macrolide antibiotic",
            half_life_hours=68.0, enzymes=[],
            organ_effects=[OrganEffect(organ="Heart", mechanism="QT prolongation", severity="moderate")]),
        DrugMeta(name="Metoprolol", drug_class="beta blocker",
            half_life_hours=4.0, enzymes=["CYP2D6"],
            organ_effects=[OrganEffect(organ="Heart", mechanism="bradycardia", severity="mild")]),
        DrugMeta(name="Amiodarone", drug_class="antiarrhythmic", is_inhibitor=True,
            therapeutic_window="narrow", half_life_hours=1500.0,
            enzymes=["CYP2D6", "CYP3A4"],
            organ_effects=[
                OrganEffect(organ="Heart", mechanism="QT prolongation", severity="severe"),
                OrganEffect(organ="Thyroid", mechanism="thyroid dysfunction", severity="moderate")
            ]),
        DrugMeta(name="Simvastatin", drug_class="statin",
            half_life_hours=2.0, enzymes=["CYP3A4"],
            organ_effects=[OrganEffect(organ="Liver", mechanism="myopathy / rhabdomyolysis", severity="severe")]),
        DrugMeta(name="Sertraline", drug_class="SSRI", is_inhibitor=True,
            half_life_hours=26.0, enzymes=["CYP2D6"],
            organ_effects=[OrganEffect(organ="Liver", mechanism="mild hepatic stress", severity="mild")]),
        DrugMeta(name="Omeprazole", drug_class="PPI", is_inhibitor=True,
            half_life_hours=1.5, enzymes=["CYP2C19"],
            organ_effects=[OrganEffect(organ="Liver", mechanism="mild hepatic stress", severity="mild")]),
        DrugMeta(name="Clopidogrel", drug_class="antiplatelet",
            half_life_hours=6.0, enzymes=["CYP2C19"],
            organ_effects=[OrganEffect(organ="Liver", mechanism="bleeding risk", severity="moderate")]),
        DrugMeta(name="Digoxin", drug_class="cardiac glycoside",
            therapeutic_window="narrow", half_life_hours=36.0,
            enzymes=["P-glycoprotein"],
            organ_effects=[OrganEffect(organ="Heart", mechanism="arrhythmia / toxicity", severity="severe")]),
        DrugMeta(name="Rifampin", drug_class="antibiotic", is_inducer=True,
            half_life_hours=3.0, enzymes=["CYP3A4", "CYP2C9"],
            organ_effects=[OrganEffect(organ="Liver", mechanism="hepatotoxicity", severity="moderate")]),
        DrugMeta(name="Carbamazepine", drug_class="anticonvulsant", is_inducer=True,
            therapeutic_window="narrow", half_life_hours=36.0,
            enzymes=["CYP3A4"],
            organ_effects=[
                OrganEffect(organ="Liver", mechanism="hepatotoxicity", severity="moderate"),
                OrganEffect(organ="CNS", mechanism="sedation / ataxia", severity="moderate")
            ]),
        DrugMeta(name="Tacrolimus", drug_class="immunosuppressant",
            therapeutic_window="narrow", half_life_hours=12.0,
            enzymes=["CYP3A4"],
            organ_effects=[OrganEffect(organ="Kidney", mechanism="nephrotoxicity", severity="severe")]),
        DrugMeta(name="Ciprofloxacin", drug_class="fluoroquinolone", is_inhibitor=True,
            half_life_hours=4.0, enzymes=["CYP1A2"],
            organ_effects=[
                OrganEffect(organ="Heart", mechanism="QT prolongation", severity="moderate"),
                OrganEffect(organ="Kidney", mechanism="crystalluria", severity="mild")
            ])
    ];
}


glob ENZYME_HOSTS = [
    ("CYP3A4", "Liver"), ("CYP2C9", "Liver"), ("CYP2D6", "Liver"),
    ("CYP2C19", "Liver"), ("CYP1A2", "Liver"), ("P-glycoprotein", "Liver")
];

glob ORGAN_SYSTEMS = [
    ("Liver", "hepatic"), ("Kidney", "renal"), ("Heart", "cardiac"),
    ("CNS", "neurologic"), ("Thyroid", "endocrine")
];


def find_drug_meta(name: str) -> DrugMeta | None {
    for m in build_drug_table() {
        if m.name.lower() == name.lower() {
            return m;
        }
    }
    return None;
}


# ---------------------------------------------------------------------------
# Lookups
# ---------------------------------------------------------------------------

def find_patient(pname: str) -> Patient | None {
    for p in [root-->[?:Patient]] {
        if p.name.lower() == pname.lower() {
            return p;
        }
    }
    return None;
}

def find_enzyme(ename: str) -> Enzyme | None {
    for e in [root-->[?:Enzyme]] {
        if e.name == ename {
            return e;
        }
    }
    return None;
}

def find_organ(oname: str) -> Organ | None {
    for o in [root-->[?:Organ]] {
        if o.name == oname {
            return o;
        }
    }
    return None;
}


# ---------------------------------------------------------------------------
# Seed walker
# ---------------------------------------------------------------------------

walker:pub seed {
    """Idempotently build the enzyme/organ skeleton."""
    can run with Root entry {
        if [-->[?:Registry]] {
            report {"status": "already_seeded"};
            disengage;
        }
        here ++> Registry(seeded=True);

        organ_map: dict[str, Organ] = {};
        for (oname, osys) in ORGAN_SYSTEMS {
            o: Organ = here ++> Organ(name=oname, system=osys);
            organ_map[oname] = o;
        }
        for (ename, ehost) in ENZYME_HOSTS {
            e: Enzyme = here ++> Enzyme(name=ename, organ=ehost);
            if ehost in organ_map {
                e +>:EnzymeIn:+> organ_map[ehost];
            }
        }
        report {"status": "seeded", "organs": len(ORGAN_SYSTEMS), "enzymes": len(ENZYME_HOSTS)};
    }
}


# ---------------------------------------------------------------------------
# Patient + drug walkers
# ---------------------------------------------------------------------------

walker:pub create_patient {
    has name: str;
    has age: int = 0;
    has kidney_gfr: float = 90.0;

    can run with Root entry {
        existing = find_patient(self.name);
        if existing is not None {
            report {"name": existing.name, "status": "exists"};
            disengage;
        }
        p: Patient = here ++> Patient(name=self.name, age=self.age,
                              kidney_function_gfr=self.kidney_gfr);
        report {"name": p.name, "status": "created"};
    }
}

walker:pub list_patients {
    can run with Root entry {
        out: list[dict] = [];
        for p in [-->[?:Patient]] {
            out.append({
                "name": p.name,
                "age": p.age,
                "kidney_gfr": p.kidney_function_gfr
            });
        }
        report out;
    }
}


walker:pub add_drug {
    has patient_name: str;
    has drug_name: str;
    has dose_mg: float = 0.0;
    has frequency: str = "once daily";

    can run with Root entry {
        patient = find_patient(self.patient_name);
        if patient is None {
            report {"status": "error", "error": f"patient {self.patient_name} not found — call seed_demo_patient or create_patient first"};
            disengage;
        }
        # Dedup
        for d in [patient-->[?:Drug]] {
            if d.name.lower() == self.drug_name.lower() {
                report {"status": "duplicate", "drug": d.name};
                disengage;
            }
        }

        meta = find_drug_meta(self.drug_name);
        today = datetime.now().strftime("%Y-%m-%d");
        if meta is None {
            new_drug: Drug = (patient +>:Prescribed(start_date=today):+> Drug(
                name=self.drug_name, dose_mg=self.dose_mg, frequency=self.frequency,
                drug_class="unknown"
            ));
            report {"status": "added_unknown", "drug": new_drug.name,
                    "warning": "interaction data unavailable"};
            disengage;
        }

        new_drug: Drug = (patient +>:Prescribed(start_date=today):+> Drug(
            name=meta.name,
            drug_class=meta.drug_class,
            dose_mg=self.dose_mg,
            frequency=self.frequency,
            is_inhibitor=meta.is_inhibitor,
            is_inducer=meta.is_inducer,
            therapeutic_window=meta.therapeutic_window,
            half_life_hours=meta.half_life_hours
        ));

        for ename in meta.enzymes {
            e = find_enzyme(ename);
            if e is not None {
                new_drug +>:MetabolizedBy:+> e;
            }
        }
        for oe in meta.organ_effects {
            o = find_organ(oe.organ);
            if o is not None {
                new_drug +>:AffectsOrgan(mechanism=oe.mechanism, severity=oe.severity):+> o;
            }
        }
        report {
            "status": "added", "drug": new_drug.name, "patient": patient.name,
            "enzymes": meta.enzymes,
            "organs": [oe.organ for oe in meta.organ_effects]
        };
    }
}


walker:pub remove_drug {
    has patient_name: str;
    has drug_name: str;

    can run with Root entry {
        p = find_patient(self.patient_name);
        if p is None {
            report {"error": "patient not found"};
            disengage;
        }
        for d in [p-->[?:Drug]] {
            if d.name.lower() == self.drug_name.lower() {
                del d;
                report {"status": "removed", "drug": self.drug_name};
                disengage;
            }
        }
        report {"status": "not_found", "drug": self.drug_name};
    }
}


walker:pub get_medications {
    has patient_name: str;

    can run with Root entry {
        p = find_patient(self.patient_name);
        if p is None {
            report [];
            disengage;
        }
        out: list[dict] = [];
        for d in [p-->[?:Drug]] {
            out.append({
                "name": d.name, "dose_mg": d.dose_mg, "frequency": d.frequency,
                "drug_class": d.drug_class,
                "is_inhibitor": d.is_inhibitor, "is_inducer": d.is_inducer,
                "therapeutic_window": d.therapeutic_window
            });
        }
        report out;
    }
}


# ---------------------------------------------------------------------------
# Conflict detection
# ---------------------------------------------------------------------------

def severity_for(drugs: list[Drug]) -> str {
    has_modifier = False;
    has_narrow = False;
    for d in drugs {
        if d.is_inhibitor or d.is_inducer {
            has_modifier = True;
        }
        if d.therapeutic_window == "narrow" {
            has_narrow = True;
        }
    }
    if has_modifier and has_narrow {
        return "critical";
    }
    if has_modifier {
        return "high";
    }
    return "moderate";
}


obj Conflict {
    has enzyme: str;
    has drugs: list[str];
    has inhibitors: list[str];
    has inducers: list[str];
    has narrow_window_drugs: list[str];
    has severity: str;
}

def conflict_to_dict(c: Conflict) -> dict {
    return {
        "enzyme": c.enzyme,
        "drugs": c.drugs,
        "inhibitors": c.inhibitors,
        "inducers": c.inducers,
        "narrow_window_drugs": c.narrow_window_drugs,
        "severity": c.severity
    };
}

def build_conflict_list(p: Patient) -> list[Conflict] {
    drugs: list[Drug] = [p-->[?:Drug]];
    enzyme_users: dict[str, list[Drug]] = {};
    for d in drugs {
        enzymes: list[Enzyme] = [d-->[?:Enzyme]];
        for e in enzymes {
            if e.name not in enzyme_users {
                enzyme_users[e.name] = [];
            }
            enzyme_users[e.name].append(d);
        }
    }
    out: list[Conflict] = [];
    for (ename, users) in enzyme_users.items() {
        if len(users) > 1 {
            inhibs = [d.name for d in users if d.is_inhibitor];
            inducs = [d.name for d in users if d.is_inducer];
            if inhibs or inducs {
                narrow = [d.name for d in users if d.therapeutic_window == "narrow"];
                out.append(Conflict(
                    enzyme=ename,
                    drugs=[d.name for d in users],
                    inhibitors=inhibs,
                    inducers=inducs,
                    narrow_window_drugs=narrow,
                    severity=severity_for(users)
                ));
            }
        }
    }
    return out;
}


def recompute_organ_risk(p: Patient) -> list[dict] {
    organs: list[Organ] = [root-->[?:Organ]];
    for o in organs {
        o.risk_score = 0.0;
    }
    sev_weight = {"mild": 0.15, "moderate": 0.35, "severe": 0.6};
    drugs: list[Drug] = [p-->[?:Drug]];
    for d in drugs {
        meta = find_drug_meta(d.name);
        if meta is None {
            continue;
        }
        for oe in meta.organ_effects {
            tgt = find_organ(oe.organ);
            if tgt is not None {
                bump = sev_weight.get(oe.severity, 0.2);
                tgt.risk_score = min(1.0, tgt.risk_score + bump);
            }
        }
    }
    out: list[dict] = [];
    for o in organs {
        out.append({"organ": o.name, "risk_score": o.risk_score});
    }
    return out;
}


walker:pub check_conflicts {
    has patient_name: str;

    can run with Root entry {
        p = find_patient(self.patient_name);
        if p is None {
            report {"error": "patient not found"};
            disengage;
        }
        conflicts = build_conflict_list(p);
        organs = recompute_organ_risk(p);
        report {
            "patient": p.name,
            "drug_count": len([p-->[?:Drug]]),
            "conflict_count": len(conflicts),
            "conflicts": [conflict_to_dict(c) for c in conflicts],
            "organ_risks": organs
        };
    }
}


# ---------------------------------------------------------------------------
# byLLM — the ONLY place a model is called.
# The type signature IS the prompt.
# ---------------------------------------------------------------------------

glob llm = Model(
    model_name="groq/llama-3.3-70b-versatile",
    api_key=os.getenv("GROQ_API_KEY") or ""
);

obj ClinicalExplanation {
    has summary: str;
    has mechanism: str;
    has clinical_risk: str;
    has recommendation: str;
    has severity_level: str;
    has references: list[str];
}

sem ClinicalExplanation = "Patient-facing medication interaction alert for a consumer health app. Never use enzyme codes (CYP3A4, etc.) in summary or recommendation.";
sem ClinicalExplanation.summary = "One clear warning the patient reads first. Name both drugs in plain language. Example tone: 'Clarithromycin may cause your cholesterol medication (Simvastatin) to build up to dangerous levels in your body. Your doctor should review this combination before you continue.' No jargon.";
sem ClinicalExplanation.mechanism = "Clinical details for the prescriber: enzyme pathways, inhibition/induction, pharmacokinetics. OK to use CYP names here.";
sem ClinicalExplanation.clinical_risk = "What could happen to THIS patient in everyday language (age, kidney function), without scaring unnecessarily but being honest.";
sem ClinicalExplanation.recommendation = "What the patient should do next: talk to doctor, do not stop meds alone, bring this report to appointment. Second person ('you').";
sem ClinicalExplanation.severity_level = "One of: low, moderate, high, critical.";
sem ClinicalExplanation.references = "Drug names involved in this interaction.";

def explain_interaction(
    drugs: list[str],
    inhibitors: list[str],
    inducers: list[str],
    enzyme: str,
    severity_class: str,
    narrow_window_drugs: list[str],
    patient_age: int,
    kidney_gfr: float
) -> ClinicalExplanation by llm();


walker:pub get_report {
    has patient_name: str;

    can run with Root entry {
        p = find_patient(self.patient_name);
        if p is None {
            report {"error": "patient not found"};
            disengage;
        }
        conflicts = build_conflict_list(p);
        organs = recompute_organ_risk(p);

        findings: list[dict] = [];
        worst = "safe";
        rank = {"safe": 0, "caution": 1, "warning": 2, "danger": 3};
        sev_to_overall = {"moderate": "caution", "high": "warning", "critical": "danger"};

        for c in conflicts {
            try {
                ce = explain_interaction(
                    drugs=c.drugs,
                    inhibitors=c.inhibitors,
                    inducers=c.inducers,
                    enzyme=c.enzyme,
                    severity_class=c.severity,
                    narrow_window_drugs=c.narrow_window_drugs,
                    patient_age=p.age,
                    kidney_gfr=p.kidney_function_gfr
                );
                findings.append({
                    "enzyme": c.enzyme,
                    "drugs": c.drugs,
                    "severity": ce.severity_level,
                    "summary": ce.summary,
                    "mechanism": ce.mechanism,
                    "clinical_risk": ce.clinical_risk,
                    "recommendation": ce.recommendation,
                    "references": ce.references
                });
            } except Exception as ex {
                findings.append({
                    "enzyme": c.enzyme,
                    "drugs": c.drugs,
                    "severity": c.severity,
                    "summary": (
                        f"⚠️ These medications ({', '.join(c.drugs)}) may not work well together. "
                        "Ask your doctor to review this combination before you continue both."
                    ),
                    "mechanism": f"Both drugs are metabolized via {c.enzyme}; one is an inhibitor/inducer.",
                    "clinical_risk": "Medication levels in your body may become too high or too low.",
                    "recommendation": "Bring this report to your next appointment. Do not stop either medication on your own.",
                    "references": c.drugs
                });
            }
            overall = sev_to_overall.get(c.severity, "caution");
            if rank[overall] > rank[worst] {
                worst = overall;
            }
        }
        report {
            "patient_name": p.name,
            "overall_risk": worst,
            "total_drugs": len([p-->[?:Drug]]),
            "conflicts_found": len(findings),
            "findings": findings,
            "organ_risks": organs,
            "generated_at": datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
        };
    }
}


walker:pub seed_demo_patient {
    """Set up Sarah Chen for the hackathon demo.
    Idempotent: dedupes any prior Sarah Chens, resets her drugs."""
    can run with Root entry {
        if not [-->[?:Registry]] {
            report {"error": "call /walker/seed first"};
            disengage;
        }
        # Collect ALL existing Sarahs (in case prior bugs created duplicates)
        sarahs: list[Patient] = [];
        for p in [root-->[?:Patient]] {
            if p.name.lower() == "sarah chen" {
                sarahs.append(p);
            }
        }
        if sarahs {
            # Keep the first, fix her attrs, blow away the rest
            keeper = sarahs[0];
            keeper.age = 68;
            keeper.weight_kg = 64.0;
            keeper.kidney_function_gfr = 55.0;
            # Reset her medications + agent memory
            for d in [keeper-->[?:Drug]] { del d; }
            for r in [keeper-->[?:Reasoning]] { del r; }
            for ev in [keeper-->[?:Evidence]] { del ev; }
            for a in [keeper-->[?:Alternative]] { del a; }
            for dr in [keeper-->[?:DoseRecommendation]] { del dr; }
            for e in [keeper-->[?:Escalation]] { del e; }
            for c in [keeper-->[?:Critique]] { del c; }
            # Delete the duplicates
            for extra in sarahs[1:] {
                for d in [extra-->[?:Drug]] { del d; }
                del extra;
            }
            report {"status": "reset", "patient": "Sarah Chen",
                    "duplicates_removed": len(sarahs) - 1};
            disengage;
        }
        here ++> Patient(name="Sarah Chen", age=68, weight_kg=64.0,
                         kidney_function_gfr=55.0);
        report {"status": "created", "patient": "Sarah Chen"};
    }
}


# ===========================================================================
# AGENTIC LAYER — PharmacistAgent
#
# A planning walker that, given a detected conflict, calls the LLM each
# iteration to pick ONE action from a fixed tool registry. Each tool either
# pulls evidence into the graph (creating Evidence / Alternative /
# DoseRecommendation nodes attached to the patient) or terminates the loop.
#
# The graph IS the agent's memory — every step it takes is durable.
# ===========================================================================

# --- Agent-side nodes (live attached to the Patient) -----------------------

node Reasoning {
    """One thought/justification the agent emitted on a specific step."""
    has step: int;
    has thought: str;
    has action: str;
    has created_at: str = "";
}

node Evidence {
    """FDA / external data pulled by the agent."""
    has source: str;
    has drug: str;
    has summary: str;
    has created_at: str = "";
}

node Alternative {
    """An alternative drug the agent proposes."""
    has drug_name: str;
    has drug_class: str;
    has replaces: str;
    has rationale: str;
    has shared_enzymes: list[str] = [];
    has created_at: str = "";
}

node DoseRecommendation {
    """A renal/hepatic dose adjustment the agent proposes."""
    has drug_name: str;
    has original_dose_mg: float;
    has recommended_dose_mg: float;
    has rationale: str;
    has created_at: str = "";
}

node Escalation {
    """The agent has decided this needs a human pharmacist."""
    has reason: str;
    has created_at: str = "";
}

edge AgentMemory {
    has step: int = 0;
}

# --- Plan / Action schema (typed = the prompt) -----------------------------

obj AgentAction {
    has tool: str;
    has thought: str;
    # All four are populated based on which tool is chosen. Pass empty
    # string for the ones not relevant to the chosen tool.
    has drug: str;
    has drug_class: str;
    has reason: str;
    has final_summary: str;
}

sem AgentAction = "ONE next action a clinical pharmacist agent should take to resolve a drug-drug interaction. Pick exactly one tool from: fetch_fda_label, find_alternatives, compute_dose_adjustment, escalate, done. ALWAYS provide all six fields — use empty string \"\" for fields not relevant to your chosen tool.";
sem AgentAction.tool = "Tool name. Must be one of: fetch_fda_label, find_alternatives, compute_dose_adjustment, escalate, done.";
sem AgentAction.thought = "One short sentence explaining why this tool is the right next step right now.";
sem AgentAction.drug = "Exact drug name when tool is fetch_fda_label or compute_dose_adjustment. Empty string otherwise.";
sem AgentAction.drug_class = "Drug class (e.g. 'macrolide antibiotic', 'statin') when tool is find_alternatives. Empty string otherwise.";
sem AgentAction.reason = "Why a human pharmacist is needed, when tool is escalate. Empty string otherwise.";
sem AgentAction.final_summary = "One-paragraph wrap-up when tool is done. Empty string otherwise.";

obj AgentState {
    """What the agent already knows. Built by the walker from graph state, then fed to the LLM each step."""
    has patient_name: str;
    has patient_age: int;
    has kidney_gfr: float;
    has conflict_enzyme: str;
    has conflict_drugs: list[str];
    has inhibitors: list[str];
    has severity: str;
    has steps_taken: list[str];
    has evidence_collected: list[str];
    has alternatives_proposed: list[str];
    has dose_recommendations: list[str];
}

sem AgentState = "Current working memory of the pharmacist agent. Use this to decide the NEXT action. Do not repeat actions already in steps_taken. Stop (tool=done) once you have at least one alternative or one dose recommendation, or after 5 steps.";

def choose_next_action(state: AgentState) -> AgentAction by llm();


# --- Tool implementations --------------------------------------------------
#
# Each tool is a pure Jac function. Some read the graph, some write to it,
# some call an external service (FDA). None call the LLM — the LLM only
# chooses WHICH tool to call.

def fda_lookup(drug_name: str) -> str {
    # Hit OpenFDA for a drug label. Tries brand → generic → substance.
    # Returns a short summary, or '' on failure.
    q = quote(drug_name.lower());
    queries = [
        f"openfda.brand_name:{q}",
        f"openfda.generic_name:{q}",
        f"openfda.substance_name:{q}"
    ];
    for query in queries {
        try {
            url = f"https://api.fda.gov/drug/label.json?search={query}&limit=1";
            resp = urlopen(url, timeout=5);
            raw = resp.read();
            body: str = raw.decode("utf-8") if isinstance(raw, bytes) else str(raw);
            data = json.loads(body);
            results = data.get("results", []) if isinstance(data, dict) else [];
            if not results {
                continue;
            }
            rec = results[0];
            warnings = rec.get("warnings", []) if isinstance(rec, dict) else [];
            interactions = rec.get("drug_interactions", []) if isinstance(rec, dict) else [];
            chunks: list[str] = [];
            if warnings {
                w0: str = str(warnings[0])[:300];
                chunks.append("WARNINGS: " + w0);
            }
            if interactions {
                i0: str = str(interactions[0])[:300];
                chunks.append("INTERACTIONS: " + i0);
            }
            if not chunks {
                return f"FDA label found for {drug_name} but no warnings/interactions populated.";
            }
            return " || ".join(chunks);
        } except Exception as ex {
            continue;
        }
    }
    return "";
}

def tool_fetch_fda_label(patient: Patient, drug: str, step: int) -> dict {
    summary = fda_lookup(drug);
    if not summary {
        summary = f"OpenFDA returned no record for {drug}. Agent will rely on graph data.";
    }
    now = datetime.now().strftime("%Y-%m-%dT%H:%M:%S");
    ev = (patient +>:AgentMemory(step=step):+> Evidence(
        source="OpenFDA", drug=drug, summary=summary, created_at=now
    ));
    return {"tool": "fetch_fda_label", "drug": drug, "summary": summary};
}

def tool_find_alternatives(patient: Patient, drug_class: str,
                            avoid_enzymes: list[str], step: int) -> dict {
    replaces: str = "";
    for d in [patient-->[?:Drug]] {
        if d.drug_class.lower() == drug_class.lower() {
            replaces = d.name;
        }
    }
    candidates: list[DrugMeta] = [];
    for m in build_drug_table() {
        if m.drug_class.lower() != drug_class.lower() {
            continue;
        }
        if m.name.lower() == replaces.lower() {
            continue;
        }
        shared = [e for e in m.enzymes if e in avoid_enzymes];
        if not shared {
            candidates.append(m);
        }
    }
    now = datetime.now().strftime("%Y-%m-%dT%H:%M:%S");
    if candidates {
        c = candidates[0];
        rationale = f"Same class as {replaces} ({drug_class}) but does NOT share enzyme(s) {avoid_enzymes}.";
        patient +>:AgentMemory(step=step):+> Alternative(
            drug_name=c.name, drug_class=c.drug_class,
            replaces=replaces, rationale=rationale,
            shared_enzymes=[], created_at=now
        );
        return {
            "tool": "find_alternatives",
            "drug_class": drug_class,
            "candidates": [x.name for x in candidates],
            "selected": c.name
        };
    }
    return {
        "tool": "find_alternatives",
        "drug_class": drug_class,
        "candidates": [],
        "note": f"No same-class alternative found that avoids {avoid_enzymes}."
    };
}

def tool_compute_dose_adjustment(patient: Patient, drug: str, step: int) -> dict {
    target: Drug | None = None;
    for d in [patient-->[?:Drug]] {
        if d.name.lower() == drug.lower() {
            target = d;
            break;
        }
    }
    if target is None {
        return {"tool": "compute_dose_adjustment", "drug": drug,
                "error": "drug not prescribed to patient"};
    }
    gfr: float = patient.kidney_function_gfr;
    original: float = target.dose_mg;
    window: str = target.therapeutic_window;
    if gfr >= 60.0 and window != "narrow" {
        return {"tool": "compute_dose_adjustment", "drug": drug,
                "original_dose_mg": original, "recommended_dose_mg": original,
                "note": "GFR adequate and drug has wide therapeutic window; no change."};
    }
    factor: float = max(0.5, min(1.0, gfr / 90.0));
    raw_dose: float = original * factor;
    new_dose: float = int(raw_dose * 10) / 10.0;
    factor_str: str = f"{factor:.2f}";
    rationale = f"Patient GFR {gfr} (normal=90+); scaling dose by {factor_str} for {window}-window drug.";
    now = datetime.now().strftime("%Y-%m-%dT%H:%M:%S");
    patient +>:AgentMemory(step=step):+> DoseRecommendation(
        drug_name=drug, original_dose_mg=original,
        recommended_dose_mg=new_dose, rationale=rationale, created_at=now
    );
    return {
        "tool": "compute_dose_adjustment",
        "drug": drug,
        "original_dose_mg": original,
        "recommended_dose_mg": new_dose,
        "rationale": rationale
    };
}

def tool_escalate(patient: Patient, reason: str, step: int) -> dict {
    now = datetime.now().strftime("%Y-%m-%dT%H:%M:%S");
    patient +>:AgentMemory(step=step):+> Escalation(reason=reason, created_at=now);
    return {"tool": "escalate", "reason": reason};
}


# --- The agent walker ------------------------------------------------------

walker:pub run_pharmacist_agent {
    """Plan-execute-reflect loop. Given a patient with a known conflict, the
    agent autonomously decides which tools to call, in what order, until
    it emits `done`. Every step is durably written to the graph."""
    has patient_name: str;
    has max_steps: int = 6;

    can run with Root entry {
        p = find_patient(self.patient_name);
        if p is None {
            report {"error": "patient not found"};
            disengage;
        }
        conflicts = build_conflict_list(p);
        if not conflicts {
            report {"status": "no_conflict", "note": "Nothing for the agent to plan around."};
            disengage;
        }
        # Plan around the worst-severity conflict
        target = conflicts[0];
        rank = {"moderate": 1, "high": 2, "critical": 3};
        for c in conflicts {
            if rank.get(c.severity, 0) > rank.get(target.severity, 0) {
                target = c;
            }
        }

        transcript: list[dict] = [];
        steps_taken: list[str] = [];
        evidence_collected: list[str] = [];
        alternatives_proposed: list[str] = [];
        dose_recommendations: list[str] = [];

        step = 0;
        while step < self.max_steps {
            state = AgentState(
                patient_name=p.name,
                patient_age=p.age,
                kidney_gfr=p.kidney_function_gfr,
                conflict_enzyme=target.enzyme,
                conflict_drugs=target.drugs,
                inhibitors=target.inhibitors,
                severity=target.severity,
                steps_taken=steps_taken,
                evidence_collected=evidence_collected,
                alternatives_proposed=alternatives_proposed,
                dose_recommendations=dose_recommendations
            );

            try {
                action = choose_next_action(state);
            } except Exception as ex {
                transcript.append({"step": step, "error": f"LLM call failed: {ex}"});
                break;
            }

            now = datetime.now().strftime("%Y-%m-%dT%H:%M:%S");
            p +>:AgentMemory(step=step):+> Reasoning(
                step=step, thought=action.thought, action=action.tool, created_at=now
            );

            tool_result: dict = {};
            if action.tool == "fetch_fda_label" {
                tool_result = tool_fetch_fda_label(p, action.drug, step);
                # Only credit the evidence if we actually got a non-empty summary.
                summary_str: str = str(tool_result.get("summary", ""));
                if summary_str and "no record" not in summary_str.lower() {
                    evidence_collected.append(action.drug);
                }
            } elif action.tool == "find_alternatives" {
                tool_result = tool_find_alternatives(
                    p, action.drug_class, [target.enzyme], step
                );
                if "selected" in tool_result {
                    alternatives_proposed.append(str(tool_result["selected"]));
                }
            } elif action.tool == "compute_dose_adjustment" {
                tool_result = tool_compute_dose_adjustment(p, action.drug, step);
                # Only credit a successful adjustment (it must have produced
                # a recommended_dose_mg and not an error).
                if "error" not in tool_result and "recommended_dose_mg" in tool_result {
                    dose_recommendations.append(action.drug);
                }
            } elif action.tool == "escalate" {
                tool_result = tool_escalate(p, action.reason, step);
            } elif action.tool == "done" {
                transcript.append({
                    "step": step, "thought": action.thought,
                    "tool": "done", "final_summary": action.final_summary
                });
                steps_taken.append("done");
                break;
            } else {
                tool_result = {"error": f"unknown tool: {action.tool}"};
            }

            transcript.append({
                "step": step,
                "thought": action.thought,
                "tool": action.tool,
                "tool_result": tool_result
            });
            steps_taken.append(action.tool);
            step += 1;
        }

        # Collect what the agent attached to the patient
        out_evidence: list[dict] = [];
        for ev in [p-->[?:Evidence]] {
            out_evidence.append({"source": ev.source, "drug": ev.drug, "summary": ev.summary});
        }
        out_alts: list[dict] = [];
        for a in [p-->[?:Alternative]] {
            out_alts.append({
                "drug_name": a.drug_name, "drug_class": a.drug_class,
                "replaces": a.replaces, "rationale": a.rationale
            });
        }
        out_doses: list[dict] = [];
        for d in [p-->[?:DoseRecommendation]] {
            out_doses.append({
                "drug_name": d.drug_name,
                "original_dose_mg": d.original_dose_mg,
                "recommended_dose_mg": d.recommended_dose_mg,
                "rationale": d.rationale
            });
        }
        out_esc: list[dict] = [];
        for e in [p-->[?:Escalation]] {
            out_esc.append({"reason": e.reason});
        }

        report {
            "patient": p.name,
            "conflict": {
                "enzyme": target.enzyme,
                "drugs": target.drugs,
                "inhibitors": target.inhibitors,
                "severity": target.severity
            },
            "steps_completed": step,
            "transcript": transcript,
            "evidence": out_evidence,
            "alternatives": out_alts,
            "dose_recommendations": out_doses,
            "escalations": out_esc
        };
    }
}


walker:pub get_agent_memory {
    """Read back everything the agent has previously attached to a patient."""
    has patient_name: str;

    can run with Root entry {
        p = find_patient(self.patient_name);
        if p is None {
            report {"error": "patient not found"};
            disengage;
        }
        out: list[dict] = [];
        for r in [p-->[?:Reasoning]] {
            out.append({
                "type": "reasoning", "step": r.step,
                "thought": r.thought, "action": r.action, "at": r.created_at
            });
        }
        for ev in [p-->[?:Evidence]] {
            out.append({
                "type": "evidence", "source": ev.source,
                "drug": ev.drug, "summary": ev.summary, "at": ev.created_at
            });
        }
        for a in [p-->[?:Alternative]] {
            out.append({
                "type": "alternative", "drug": a.drug_name,
                "replaces": a.replaces, "rationale": a.rationale, "at": a.created_at
            });
        }
        for d in [p-->[?:DoseRecommendation]] {
            out.append({
                "type": "dose", "drug": d.drug_name,
                "original_dose_mg": d.original_dose_mg,
                "recommended_dose_mg": d.recommended_dose_mg,
                "rationale": d.rationale, "at": d.created_at
            });
        }
        for e in [p-->[?:Escalation]] {
            out.append({"type": "escalation", "reason": e.reason, "at": e.created_at});
        }
        report out;
    }
}


walker:pub clear_agent_memory {
    """Wipe a patient's agent history (for a fresh demo)."""
    has patient_name: str;

    can run with Root entry {
        p = find_patient(self.patient_name);
        if p is None {
            report {"error": "patient not found"};
            disengage;
        }
        n = 0;
        for r in [p-->[?:Reasoning]] { del r; n += 1; }
        for ev in [p-->[?:Evidence]] { del ev; n += 1; }
        for a in [p-->[?:Alternative]] { del a; n += 1; }
        for d in [p-->[?:DoseRecommendation]] { del d; n += 1; }
        for e in [p-->[?:Escalation]] { del e; n += 1; }
        for c in [p-->[?:Critique]] { del c; n += 1; }
        report {"status": "cleared", "nodes_removed": n};
    }
}


# ===========================================================================
# SAFETYCRITIC — second agent that audits PharmacistAgent's work
#
# Walks the patient graph INDEPENDENTLY. For each conflict it asks:
#   - Did the PharmacistAgent address it? (look for Alternative/DoseRecommendation
#     attached to the patient that names one of the conflicting drugs)
#   - Even if addressed, are there residual graph-level risks the pharmacist
#     missed? (e.g. proposed alternative still has a severe AffectsOrgan edge)
#
# The LLM is called ONCE at the end to write a verdict given the audit data
# the critic walker collected by traversal — same pattern as PharmacistAgent,
# but the critic's job is to disagree, not to plan.
# ===========================================================================

node Critique {
    """One judgement the critic emitted about a specific conflict."""
    has conflict_enzyme: str;
    has conflict_drugs: list[str];
    has verdict: str;          # "addressed" | "missed" | "partial" | "residual_risk"
    has reasoning: str;
    has severity: str;
    has created_at: str = "";
}

obj CritiqueAudit {
    """What the critic walker observed before calling the LLM."""
    has patient_name: str;
    has patient_age: int;
    has kidney_gfr: float;
    has total_conflicts: int;
    has conflicts: list[dict];
    has pharmacist_alternatives: list[dict];   # {drug, replaces}
    has pharmacist_dose_adjustments: list[dict]; # {drug, original, recommended}
    has pharmacist_escalations: list[str];
    # Per-conflict audit notes the critic generated by graph traversal:
    has addressed_conflicts: list[dict];  # conflict + which pharmacist action covers it
    has unaddressed_conflicts: list[dict];
    has alternative_residual_risks: list[dict]; # {alt_drug, organ, severity}
}

obj CritiqueReport {
    has overall_verdict: str;  # "agreed" | "partial_agreement" | "disagree"
    has summary: str;
    has missed_conflicts: list[str];
    has agreed_actions: list[str];
    has additional_concerns: list[str];
    has recommendation: str;
}

sem CritiqueAudit = "A second-opinion review of a clinical pharmacist agent's work. Use this audit data to render a critique verdict.";
sem CritiqueReport = "An independent safety critique of PharmacistAgent's proposed plan.";
sem CritiqueReport.overall_verdict = "One of: agreed, partial_agreement, disagree.";
sem CritiqueReport.summary = "One pharmacist-grade sentence: does PharmacistAgent's plan adequately protect this patient?";
sem CritiqueReport.missed_conflicts = "Conflicts present in the graph that PharmacistAgent did not address. Empty list if all addressed.";
sem CritiqueReport.agreed_actions = "Things PharmacistAgent did that you concur with.";
sem CritiqueReport.additional_concerns = "Risks the pharmacist overlooked — e.g. proposed alternative still hits a severe organ pathway, narrow-window drug at impaired GFR.";
sem CritiqueReport.recommendation = "What the clinician should do next: accept the plan / accept with caveats / escalate.";

def render_critique(audit: CritiqueAudit) -> CritiqueReport by llm();


def alt_residual_risks(alt_drug: str) -> list[dict] {
    # Look up whether an alternative drug has any severe organ effects of its own.
    out: list[dict] = [];
    meta = find_drug_meta(alt_drug);
    if meta is None {
        return out;
    }
    for oe in meta.organ_effects {
        if oe.severity == "severe" or oe.severity == "moderate" {
            out.append({
                "alt_drug": alt_drug,
                "organ": oe.organ,
                "mechanism": oe.mechanism,
                "severity": oe.severity
            });
        }
    }
    return out;
}


walker:pub run_safety_critic {
    """Audit PharmacistAgent's plan. Independent traversal + LLM verdict."""
    has patient_name: str;

    can run with Root entry {
        p = find_patient(self.patient_name);
        if p is None {
            report {"error": "patient not found"};
            disengage;
        }

        # 1. Re-derive conflicts from the live graph (don't trust prior state).
        conflicts = build_conflict_list(p);

        # 2. Read what PharmacistAgent already attached to this patient.
        pharm_alts: list[dict] = [];
        for a in [p-->[?:Alternative]] {
            pharm_alts.append({"drug": a.drug_name, "replaces": a.replaces, "rationale": a.rationale});
        }
        pharm_doses: list[dict] = [];
        for d in [p-->[?:DoseRecommendation]] {
            pharm_doses.append({
                "drug": d.drug_name,
                "original": d.original_dose_mg,
                "recommended": d.recommended_dose_mg
            });
        }
        pharm_escs: list[str] = [];
        for e in [p-->[?:Escalation]] {
            pharm_escs.append(e.reason);
        }

        # 3. Per-conflict audit: was each one addressed?
        addressed: list[dict] = [];
        unaddressed: list[dict] = [];
        replaced_drugs: list[str] = [a["replaces"].lower() for a in pharm_alts];
        adjusted_drugs: list[str] = [d["drug"].lower() for d in pharm_doses];
        for c in conflicts {
            drugs_lower = [d.lower() for d in c.drugs];
            # Conflict is addressed if ANY of its drugs were replaced or had a dose adjustment
            handled_by = [];
            for dl in drugs_lower {
                if dl in replaced_drugs {
                    handled_by.append(f"{dl}: replaced");
                }
                if dl in adjusted_drugs {
                    handled_by.append(f"{dl}: dose adjusted");
                }
            }
            entry_dict = {
                "enzyme": c.enzyme,
                "drugs": c.drugs,
                "severity": c.severity,
                "narrow_window_drugs": c.narrow_window_drugs
            };
            if handled_by {
                entry_dict["actions"] = handled_by;
                addressed.append(entry_dict);
            } else {
                unaddressed.append(entry_dict);
            }
        }

        # 4. Residual risk check: any proposed alternatives still hit major organs?
        residual: list[dict] = [];
        for a in pharm_alts {
            for r in alt_residual_risks(str(a["drug"])) {
                residual.append(r);
            }
        }

        audit = CritiqueAudit(
            patient_name=p.name,
            patient_age=p.age,
            kidney_gfr=p.kidney_function_gfr,
            total_conflicts=len(conflicts),
            conflicts=[conflict_to_dict(c) for c in conflicts],
            pharmacist_alternatives=pharm_alts,
            pharmacist_dose_adjustments=pharm_doses,
            pharmacist_escalations=pharm_escs,
            addressed_conflicts=addressed,
            unaddressed_conflicts=unaddressed,
            alternative_residual_risks=residual
        );

        # 5. Persist a Critique node per unaddressed conflict (graph memory).
        now = datetime.now().strftime("%Y-%m-%dT%H:%M:%S");
        for u in unaddressed {
            drugs_list: list[str] = [str(x) for x in u["drugs"]];
            p +>:AgentMemory(step=0):+> Critique(
                conflict_enzyme=str(u["enzyme"]),
                conflict_drugs=drugs_list,
                verdict="missed",
                reasoning=f"PharmacistAgent proposed no alternative or dose adjustment for any drug in {u['drugs']} on {u['enzyme']}.",
                severity=str(u["severity"]),
                created_at=now
            );
        }
        for r in residual {
            p +>:AgentMemory(step=0):+> Critique(
                conflict_enzyme="",
                conflict_drugs=[r["alt_drug"]],
                verdict="residual_risk",
                reasoning=f"Proposed alternative {r['alt_drug']} still has a {r['severity']} effect on {r['organ']} ({r['mechanism']}).",
                severity=str(r["severity"]),
                created_at=now
            );
        }

        # 6. Call LLM for the human-readable verdict.
        report_dict: dict = {};
        try {
            verdict = render_critique(audit);
            report_dict = {
                "overall_verdict": verdict.overall_verdict,
                "summary": verdict.summary,
                "missed_conflicts": verdict.missed_conflicts,
                "agreed_actions": verdict.agreed_actions,
                "additional_concerns": verdict.additional_concerns,
                "recommendation": verdict.recommendation
            };
        } except Exception as ex {
            # Fall back to a deterministic summary built from the audit alone.
            v: str = "disagree" if unaddressed else (
                "partial_agreement" if residual else "agreed"
            );
            report_dict = {
                "overall_verdict": v,
                "summary": (
                    f"PharmacistAgent addressed {len(addressed)}/{len(conflicts)} conflict(s). "
                    + (f"{len(unaddressed)} conflict(s) remain unaddressed. " if unaddressed else "")
                    + (f"{len(residual)} residual risk(s) on proposed alternatives." if residual else "")
                ),
                "missed_conflicts": [f"{u['enzyme']}: {u['drugs']}" for u in unaddressed],
                "agreed_actions": [
                    f"{a['drug']} replaces {a['replaces']}" for a in pharm_alts
                ] + [
                    f"{d['drug']}: {d['original']}mg -> {d['recommended']}mg" for d in pharm_doses
                ],
                "additional_concerns": [
                    f"{r['alt_drug']} still has {r['severity']} effect on {r['organ']}" for r in residual
                ],
                "recommendation": "escalate" if unaddressed else "accept with caveats"
            };
        }

        report {
            "patient": p.name,
            "audit": {
                "total_conflicts": len(conflicts),
                "addressed": addressed,
                "unaddressed": unaddressed,
                "residual_risks": residual,
                "pharmacist_alternatives": pharm_alts,
                "pharmacist_dose_adjustments": pharm_doses,
                "pharmacist_escalations": pharm_escs
            },
            "verdict": report_dict
        };
    }
}


walker:pub get_critic_memory {
    has patient_name: str;

    can run with Root entry {
        p = find_patient(self.patient_name);
        if p is None {
            report {"error": "patient not found"};
            disengage;
        }
        out: list[dict] = [];
        for c in [p-->[?:Critique]] {
            out.append({
                "verdict": c.verdict,
                "severity": c.severity,
                "enzyme": c.conflict_enzyme,
                "drugs": c.conflict_drugs,
                "reasoning": c.reasoning,
                "at": c.created_at
            });
        }
        report out;
    }
}


walker:pub clear_critic_memory {
    has patient_name: str;

    can run with Root entry {
        p = find_patient(self.patient_name);
        if p is None {
            report {"error": "patient not found"};
            disengage;
        }
        n = 0;
        for c in [p-->[?:Critique]] { del c; n += 1; }
        report {"status": "cleared", "nodes_removed": n};
    }
}


# Also extend clear_agent_memory to wipe Critiques (otherwise they linger
# and confuse the next demo run).


# ---------------------------------------------------------------------------
# CLI demo entry — `jac run main.jac`
# ---------------------------------------------------------------------------

with entry {
    # CLI demo only — skip when running under `jac start` (server). In server
    # mode every walker call must run inside the caller's auth context so the
    # caller owns the nodes it creates; running these here under the system
    # root would create enzyme/organ nodes the demo user can't connect to.
    if __name__ != "__main__" {
        # noop — being imported by the server
    } else {
        print("MediGraph: seeding skeleton...");
        root spawn seed();
        root spawn seed_demo_patient();

    print("\n[1] Add Metoprolol (safe)");
    r1 = root spawn add_drug(patient_name="Sarah Chen", drug_name="Metoprolol",
                              dose_mg=50.0, frequency="once daily");
    print(" ", r1.reports);
    r1c = root spawn check_conflicts(patient_name="Sarah Chen");
    print("  conflicts:", r1c.reports[0]["conflict_count"]);

    print("\n[2] Add Simvastatin (safe)");
    r2 = root spawn add_drug(patient_name="Sarah Chen", drug_name="Simvastatin",
                              dose_mg=40.0, frequency="once daily");
    print(" ", r2.reports);
    r2c = root spawn check_conflicts(patient_name="Sarah Chen");
    print("  conflicts:", r2c.reports[0]["conflict_count"]);

    print("\n[3] Add Clarithromycin -- CYP3A4 inhibitor, expect CONFLICT");
    r3 = root spawn add_drug(patient_name="Sarah Chen", drug_name="Clarithromycin",
                              dose_mg=500.0, frequency="twice daily");
    print(" ", r3.reports);
    r3c = root spawn check_conflicts(patient_name="Sarah Chen");
    rep = r3c.reports[0];
    print("  conflicts:", rep["conflict_count"]);
    for c in rep["conflicts"] {
        print("  --", c["enzyme"], "::", c["drugs"], "severity:", c["severity"]);
    }
    print("  organ risk:", rep["organ_risks"]);

    print("\n[4] PharmacistAgent: plan a response to the conflict");
    root spawn clear_agent_memory(patient_name="Sarah Chen");
    ar = root spawn run_pharmacist_agent(patient_name="Sarah Chen", max_steps=6);
    if ar.reports {
        a = ar.reports[0];
        print("  conflict targeted:", a.get("conflict"));
        print("  steps completed:", a.get("steps_completed"));
        for t in a.get("transcript", []) {
            tool = t.get("tool", "?");
            thought = t.get("thought", "");
            print(f"    step {t.get('step')}: [{tool}] {thought}");
            if "tool_result" in t {
                print(f"      -> {t['tool_result']}");
            }
            if "final_summary" in t {
                print(f"      SUMMARY: {t['final_summary']}");
            }
        }
        if a.get("alternatives") {
            print("  alternatives proposed:");
            for alt in a["alternatives"] {
                print(f"    - {alt['drug_name']} (replaces {alt['replaces']}): {alt['rationale']}");
            }
        }
        if a.get("dose_recommendations") {
            print("  dose recommendations:");
            for dr in a["dose_recommendations"] {
                print(f"    - {dr['drug_name']}: {dr['original_dose_mg']} mg -> {dr['recommended_dose_mg']} mg ({dr['rationale']})");
            }
        }
    }
    }
}
