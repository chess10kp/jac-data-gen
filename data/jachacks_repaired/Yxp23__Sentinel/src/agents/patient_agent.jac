"""
Patient Pattern Agent — Step 4c.

Detects suspicious patient-level patterns:
  1. multi_provider     — patient billed by 3+ different providers
  2. high_volume        — patient has 10+ sampled claims
  3. post_death_claim   — deceased patient has claims dated after DOD
  4. fraud_provider_overlap — 2+ of the billing providers are fraud-labeled

Run:
  jac run src/agents/patient_agent.jac
"""

::py::
import sys, os as _os
_proj_root = _os.path.abspath(_os.path.join(_os.path.dirname(__file__), '..', '..'))
if _proj_root not in sys.path:
    sys.path.insert(0, _proj_root)
sys.setrecursionlimit(10000)
::py::

include src.agents.patient_walker;

import from src.loader.load_data { load_subset }

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

with entry {
    data = load_subset(provider_limit=30, non_fraud_sample=15);

    providers = data["providers"];
    patients  = data["patients"];
    claims    = data["claims"];

    prov_index: dict = {};
    pat_index:  dict = {};
    phys_index: dict = {};

    for p in providers {
        fl = "Yes";
        if not p["fraud_label"] { fl = "No"; }
        tc = p.get("total_claims", 0) or 0;
        ta = p.get("total_amount", 0.0) or 0.0;
        ic = p.get("inpatient_count", 0) or 0;
        oc = p.get("outpatient_count", 0) or 0;
        prov_node = Provider(
            id=p["id"], fraud_label=fl,
            total_claims=tc, total_amount=ta,
            inpatient_count=ic, outpatient_count=oc
        );
        root ++> prov_node;
        prov_index[p["id"]] = prov_node;
    }

    for p in patients {
        g = p["gender"];
        gender_int = 0;
        if g == "M" { gender_int = 1; } elif g == "F" { gender_int = 2; }
        state_int = 0;
        if p["state"] is not None { state_int = p["state"]; }
        age_int = 0;
        if p["age"] is not None { age_int = p["age"]; }
        ip_amt = 0.0;
        if p["ip_annual_reimbursed"] is not None { ip_amt = p["ip_annual_reimbursed"]; }
        op_amt = 0.0;
        if p["op_annual_reimbursed"] is not None { op_amt = p["op_annual_reimbursed"]; }
        pat_node = Patient(
            id=p["id"], gender=gender_int, state=state_int, age=age_int,
            chronic_conditions=p["chronic_conditions"], deceased=p["deceased"],
            ip_annual_reimbursed=ip_amt, op_annual_reimbursed=op_amt
        );
        pat_index[p["id"]] = pat_node;
    }

    for c in claims {
        pid = c["provider_id"];
        prov_node = prov_index.get(pid) as Provider;
        if not prov_node { continue; }
        amt = 0.0;
        if c["amount"] is not None { amt = c["amount"]; }
        start = "";
        if c["claim_start"] is not None { start = c["claim_start"]; }
        end_dt = "";
        if c["claim_end"] is not None { end_dt = c["claim_end"]; }
        los = 0;
        if c["los_days"] is not None { los = c["los_days"]; }
        claim_node = Claim(
            id=c["id"], amount=amt, claim_type=c["type"],
            claim_start=start, claim_end=end_dt, los_days=los,
            diagnosis_codes=c["diagnosis_codes"],
            procedure_codes=c["procedure_codes"],
            provider_id=pid, bene_id=c["bene_id"]
        );
        prov_node ++> claim_node;
        bene_id = c["bene_id"];
        pat_node = pat_index.get(bene_id) as Patient;
        if pat_node { pat_node ++> claim_node; }
        phys_id = c["attending_physician"];
        if phys_id {
            if phys_id not in phys_index {
                phys_index[phys_id] = Physician(id=phys_id);
            }
            claim_node ++> phys_index[phys_id];
        }
    }

    deceased_map: dict = {};
    for p in patients {
        dod_val = p.get("dod", None) or "";
        deceased_map[p["id"]] = {
            "deceased": p["deceased"],
            "dod": dod_val
        };
    }

    print("[patient] Graph ready. Running Patient Pattern Agent...\n");

    agent = root spawn PatientPatternAgent(deceased_lookup=deceased_map);

    print(f"\n[patient] ── Results ──────────────────────────────────");
    high_risk  = [];
    med_risk   = [];
    for f in agent.findings {
        if f.risk_level == "HIGH"   { high_risk.append(f); }
        elif f.risk_level == "MEDIUM" { med_risk.append(f); }
    }
    print(f"  Total patients assessed : {len(agent.findings)}");
    print(f"  HIGH risk               : {len(high_risk)}");
    print(f"  MEDIUM risk             : {len(med_risk)}");

    for f in agent.findings {
        print(f"\n  [{f.risk_level}] {f.patient_id}");
        print(f"    Flags     : {f.flags}");
        print(f"    Reasoning : {f.reasoning[:250]}...");
    }
    print("\n[patient] ────────────────────────────────────────────");
}
