"""
Temporal Anomaly Agent — Step 4d.

Detects fraud patterns invisible to billing/collusion/patient agents by
examining WHEN claims happened, not how much they cost:
  1. overlapping_stays  — patient in two hospitals at once (impossible)
  2. claim_burst        — 5+ claims in 7-day window (batch fabrication)
  3. patient_shuttling  — same-day discharge→admission between providers 2+x
  4. post_death_claim   — claims filed after recorded death date

Run:
  jac run src/agents/temporal_agent.jac
"""

::py::
import sys, os as _os
_proj_root = _os.path.abspath(_os.path.join(_os.path.dirname(__file__), '..', '..'))
if _proj_root not in sys.path:
    sys.path.insert(0, _proj_root)
sys.setrecursionlimit(10000)
::py::

include src.agents.temporal_walker;

import from src.loader.load_data { load_subset }

# ---------------------------------------------------------------------------
# Entry point — minimal graph: Provider + Claim nodes only (no Patient/Physician)
# ---------------------------------------------------------------------------

with entry {
    ::py::
    import time as _t0
    _build_start = _t0.time()
    ::py::

    data = load_subset(provider_limit=200, non_fraud_sample=100, claims_per_provider=30);

    providers = data["providers"];
    patients  = data["patients"];
    claims    = data["claims"];

    prov_index: dict = {};

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
    }

    ::py::
    _build_elapsed = _t0.time() - _build_start
    print(f"[temporal] Graph built in {_build_elapsed:.1f}s  "
          f"({len(providers)} providers, {len(claims)} sampled claims)")
    ::py::

    deceased_map: dict = {};
    for p in patients {
        dod_val = p.get("dod", None) or "";
        deceased_map[p["id"]] = {
            "deceased": p["deceased"],
            "dod": dod_val
        };
    }

    ::py::
    _deceased_count = sum(1 for v in deceased_map.values() if v["deceased"])
    print(f"[temporal] deceased_map: {len(deceased_map)} patients, {_deceased_count} deceased")
    ::py::

    print("[temporal] Graph ready. Running Temporal Anomaly Agent...\n");

    agent = root spawn TemporalAnomalyAgent(deceased_lookup=deceased_map);

    print(f"\n[temporal] ── Results ──────────────────────────────────");
    high_risk = [];
    med_risk  = [];
    for f in agent.findings {
        if f.risk_level == "HIGH"   { high_risk.append(f); }
        elif f.risk_level == "MEDIUM" { med_risk.append(f); }
    }
    print(f"  Total patients assessed : {len(agent.findings)}");
    print(f"  HIGH risk               : {len(high_risk)}");
    print(f"  MEDIUM risk             : {len(med_risk)}");

    for f in agent.findings {
        print(f"\n  [{f.risk_level}] {f.patient_id}");
        print(f"    Type      : {f.anomaly_type}");
        print(f"    Providers : {f.involved_providers}");
        print(f"    Evidence  : {f.timeline_evidence[:200]}");
        print(f"    Reasoning : {f.reasoning[:200]}...");
    }
    print("\n[temporal] ────────────────────────────────────────────");
}
