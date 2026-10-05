"""
Synthesis Agent — Step 5.

Runs all three specialist agents on a single graph build and synthesizes
their findings into a unified CaseFile per flagged provider.

Run:
  jac run src/agents/synthesis_agent.jac
"""

::py::
import sys, os as _os
_proj_root = _os.path.abspath(_os.path.join(_os.path.dirname(__file__), '..', '..'))
if _proj_root not in sys.path:
    sys.path.insert(0, _proj_root)
sys.setrecursionlimit(10000)
::py::

include src.agents.billing_walker;
include src.agents.collusion_walker;
include src.agents.patient_walker;
include src.agents.temporal_walker;

import from src.loader.load_data { load_subset }

# ---------------------------------------------------------------------------
# Output types
# ---------------------------------------------------------------------------

obj SynthesisVerdict {
    has overall_risk_level: str,
        combined_reasoning: str,
        recommended_action: str,
        estimated_fraud_amount: float;
}

obj CaseFile {
    has provider_id: str,
        overall_risk_level: str,
        billing_findings: list[str],
        collusion_findings: list[str],
        patient_findings: list[str],
        temporal_findings: list[str],
        combined_reasoning: str,
        recommended_action: str,
        estimated_fraud_amount: float;
}

# ---------------------------------------------------------------------------
# byLLM function — LLM only fills SynthesisVerdict (no list fields to parse)
# ---------------------------------------------------------------------------

# synthesize_case implemented via direct OpenAI call in the entry block (byllm MTIR
# crashes when 4+ byLLM functions are co-loaded; direct API call is more reliable).

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

with entry {
    data = load_subset(provider_limit=200, non_fraud_sample=100, claims_per_provider=30);

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

    # deceased lookup for PatientPatternAgent
    deceased_map: dict = {};
    for p in patients {
        dod_val = p.get("dod", None) or "";
        deceased_map[p["id"]] = {
            "deceased": p["deceased"],
            "dod": dod_val
        };
    }

    # patient → provider mapping for cross-referencing patient findings to providers
    pat_to_provs: dict = {};
    for c in claims {
        bene = c["bene_id"];
        pid  = c["provider_id"];
        if bene not in pat_to_provs {
            pat_to_provs[bene] = [];
        }
        if pid not in pat_to_provs[bene] {
            pat_to_provs[bene].append(pid);
        }
    }

    print("[synthesis] Graph ready. Running all agents...\n");

    # ── Run all four agents ───────────────────────────────────────────────
    billing_agent   = root spawn BillingVolumeAgent();
    collusion_agent = root spawn CollusionAgent();
    patient_agent   = root spawn PatientPatternAgent(deceased_lookup=deceased_map);
    temporal_agent  = root spawn TemporalAnomalyAgent(deceased_lookup=deceased_map);

    print(f"\n[synthesis] Agent results:");
    print(f"  Billing   : {len(billing_agent.findings)} provider findings");
    print(f"  Collusion : {len(collusion_agent.findings)} ring findings");
    print(f"  Patient   : {len(patient_agent.findings)} patient findings");
    print(f"  Temporal  : {len(temporal_agent.findings)} patient findings\n");

    # ── Index billing findings by provider_id ────────────────────────────
    provider_billing: dict = {};
    for f in billing_agent.findings {
        provider_billing[f.provider_id] = f;
    }

    # ── Index collusion rings by provider_id (one ring → multiple providers) ──
    provider_collusion: dict = {};
    for ring in collusion_agent.findings {
        for pid in ring.connected_providers {
            if pid not in provider_collusion {
                provider_collusion[pid] = [];
            }
            provider_collusion[pid].append(ring);
        }
    }

    # ── Index patient findings by provider_id via pat_to_provs ───────────
    provider_patients: dict = {};
    for pf in patient_agent.findings {
        prov_list = pat_to_provs.get(pf.patient_id, []);
        for pid in prov_list {
            if pid not in provider_patients {
                provider_patients[pid] = [];
            }
            provider_patients[pid].append(pf);
        }
    }

    # ── Index temporal findings by provider_id via pat_to_provs ──────────
    provider_temporal: dict = {};
    for tf in temporal_agent.findings {
        prov_list = pat_to_provs.get(tf.patient_id, []);
        for pid in prov_list {
            if pid not in provider_temporal {
                provider_temporal[pid] = [];
            }
            provider_temporal[pid].append(tf);
        }
    }

    # ── Collect all flagged providers ────────────────────────────────────
    all_flagged: list[str] = [];
    for pid in provider_billing {
        if pid not in all_flagged { all_flagged.append(pid); }
    }
    for pid in provider_collusion {
        if pid not in all_flagged { all_flagged.append(pid); }
    }
    for pid in provider_patients {
        if pid not in all_flagged { all_flagged.append(pid); }
    }
    for pid in provider_temporal {
        if pid not in all_flagged { all_flagged.append(pid); }
    }

    print(f"[synthesis] {len(all_flagged)} providers appear in at least one agent's findings.");
    print(f"[synthesis] Synthesizing case files...\n");

    # ── Synthesize one CaseFile per flagged provider ─────────────────────
    case_files: list[CaseFile] = [];

    for pid in all_flagged {
        prov_node = prov_index.get(pid) as Provider;
        if not prov_node { continue; }

        # Billing evidence
        b_risk      = "";
        b_anomalies: list[str] = [];
        b_reasoning = "";
        bf = provider_billing.get(pid);
        if bf {
            b_risk      = bf.risk_level;
            b_anomalies = bf.anomalies;
            b_reasoning = bf.reasoning;
        }

        # Collusion evidence
        rings = provider_collusion.get(pid, []);
        c_ring_count = len(rings);
        c_physicians: list[str] = [];
        c_max_risk   = "";
        c_total_amt  = 0.0;
        for ring in rings {
            c_total_amt += ring.total_ring_amount;
            if ring.physician_id not in c_physicians {
                c_physicians.append(ring.physician_id);
            }
            if c_max_risk == "" {
                c_max_risk = ring.risk_level;
            } elif ring.risk_level == "HIGH" {
                c_max_risk = "HIGH";
            } elif ring.risk_level == "MEDIUM" and c_max_risk == "LOW" {
                c_max_risk = "MEDIUM";
            }
        }

        # Patient evidence
        pat_findings = provider_patients.get(pid, []);
        p_flagged    = len(pat_findings);
        p_high_cnt   = 0;
        p_flags_seen: list[str] = [];
        for pf in pat_findings {
            if pf.risk_level == "HIGH" { p_high_cnt += 1; }
            for flag in pf.flags {
                if flag not in p_flags_seen { p_flags_seen.append(flag); }
            }
        }

        # Temporal evidence
        temp_findings = provider_temporal.get(pid, []);
        t_count   = len(temp_findings);
        t_high    = 0;
        t_types: list[str] = [];
        for tf in temp_findings {
            if tf.risk_level == "HIGH" { t_high += 1; }
            if tf.anomaly_type not in t_types { t_types.append(tf.anomaly_type); }
        }

        # Assemble human-readable finding lists
        billing_strs: list[str] = [];
        if b_risk {
            billing_strs.append(f"risk={b_risk}, anomalies={b_anomalies}");
        }
        collusion_strs: list[str] = [];
        for ring in rings {
            collusion_strs.append(
                f"physician={ring.physician_id}, providers={ring.connected_providers}, "
                f"fraud_in_ring={ring.fraud_providers_in_ring}, "
                f"amount=${ring.total_ring_amount:,.0f}, risk={ring.risk_level}"
            );
        }
        patient_strs: list[str] = [];
        for pf in pat_findings {
            patient_strs.append(
                f"patient={pf.patient_id}, risk={pf.risk_level}, flags={pf.flags}"
            );
        }
        temporal_strs: list[str] = [];
        for tf in temp_findings {
            temporal_strs.append(
                f"patient={tf.patient_id}, type={tf.anomaly_type}, "
                f"risk={tf.risk_level}, evidence={tf.timeline_evidence[:120]}"
            );
        }

        print(f"[synthesis] Synthesizing {pid} "
              f"(billing={b_risk or 'none'}, collusion_rings={c_ring_count}, "
              f"patient_flags={p_flagged}, temporal={t_count})...");

        ::py::
        # ── Rule-based synthesis (no LLM required) ──────────────────────
        # Risk rules (same logic as the original LLM prompt):
        #   HIGH: billing HIGH + any corroboration, OR collusion HIGH,
        #         OR temporal HIGH >= 1, OR patient HIGH >= 3 + billing >= MEDIUM
        #   MEDIUM: any single MEDIUM signal
        #   LOW: everything else
        _billing_high   = b_risk == "HIGH"
        _billing_medium = b_risk in ("HIGH", "MEDIUM")
        _corroborated   = c_ring_count > 0 or p_flagged > 0 or t_count > 0
        _collusion_high = c_max_risk == "HIGH"
        _temporal_high  = t_high >= 1
        _patient_storm  = p_high_cnt >= 3 and _billing_medium

        if (_billing_high and _corroborated) or _collusion_high or _temporal_high or _patient_storm:
            _overall_risk = "HIGH"
        elif _billing_medium or c_ring_count > 0 or p_flagged > 0 or t_count > 0:
            _overall_risk = "MEDIUM"
        else:
            _overall_risk = "LOW"

        # Estimated fraud: total billed amount for HIGH, 30 % for MEDIUM
        if _overall_risk == "HIGH":
            _estimated_fraud = float(prov_node.total_amount)
        elif _overall_risk == "MEDIUM":
            _estimated_fraud = float(prov_node.total_amount) * 0.3
        else:
            _estimated_fraud = 0.0

        # Rule-based reasoning narrative
        _parts = []
        if b_risk:
            _anom_txt = (", ".join(b_anomalies[:2]) if b_anomalies else "none detected")
            _parts.append(f"Billing analysis shows {b_risk} risk: {_anom_txt}")
        if c_ring_count > 0:
            _phys_txt = ", ".join(c_physicians[:3])
            _parts.append(
                f"Collusion network: {c_ring_count} ring(s) via physician(s) {_phys_txt}, "
                f"${c_total_amt:,.0f} flowing through ring (risk={c_max_risk})"
            )
        if p_flagged > 0:
            _flag_txt = ", ".join(list(p_flags_seen)[:3])
            _parts.append(
                f"Patient patterns: {p_flagged} flagged ({p_high_cnt} HIGH risk); "
                f"flags include {_flag_txt}"
            )
        if t_count > 0:
            _type_txt = ", ".join(t_types[:3])
            _parts.append(
                f"Temporal anomalies: {t_count} found ({t_high} HIGH risk); "
                f"types: {_type_txt}"
            )
        if not _parts:
            _parts.append("No significant anomalies detected across all four specialist agents.")
        _combined_reasoning = ". ".join(_parts) + f". Provider billed {prov_node.total_claims} claims totalling ${prov_node.total_amount:,.0f}."

        # Action based on risk level
        if _overall_risk == "HIGH":
            _recommended_action = (
                f"Initiate immediate audit of provider {pid}. "
                + ("Investigate collusion ring and shared physician network. " if c_ring_count > 0 else "")
                + ("Review billing volume anomalies against peer benchmarks. " if b_risk else "")
                + "Refer to CMS Office of Inspector General for further investigation."
            )
        elif _overall_risk == "MEDIUM":
            _recommended_action = (
                f"Flag provider {pid} for enhanced monitoring. "
                "Review claims from the past 12 months and cross-reference patient and physician patterns."
            )
        else:
            _recommended_action = "Continue routine monitoring. No immediate action required."
        ::py::

        case_file = CaseFile(
            provider_id          = pid,
            overall_risk_level   = _overall_risk as str,
            billing_findings     = billing_strs,
            collusion_findings   = collusion_strs,
            patient_findings     = patient_strs,
            temporal_findings    = temporal_strs,
            combined_reasoning   = _combined_reasoning as str,
            recommended_action   = _recommended_action as str,
            estimated_fraud_amount = _estimated_fraud as float,
        );

        case_files.append(case_file);
        print(f"  → overall_risk={case_file.overall_risk_level}, "
              f"estimated_fraud=${case_file.estimated_fraud_amount:,.0f}");
    }

    # ── Summary ──────────────────────────────────────────────────────────
    high_cases:   list[CaseFile] = [];
    med_cases:    list[CaseFile] = [];
    low_cases:    list[CaseFile] = [];
    fraud_total   = 0.0;

    for cf in case_files {
        if cf.overall_risk_level == "HIGH" {
            high_cases.append(cf);
            fraud_total += cf.estimated_fraud_amount;
        } elif cf.overall_risk_level == "MEDIUM" {
            med_cases.append(cf);
        } else {
            low_cases.append(cf);
        }
    }

    print(f"\n[synthesis] ── Case File Summary ─────────────────────────");
    print(f"  Total case files generated : {len(case_files)}");
    print(f"  HIGH risk cases            : {len(high_cases)}");
    print(f"  MEDIUM risk cases          : {len(med_cases)}");
    print(f"  LOW risk cases             : {len(low_cases)}");
    print(f"  Estimated fraud (HIGH)     : ${fraud_total:,.0f}");

    if high_cases {
        print(f"\n  ── HIGH RISK CASES ──────────────────────────────────");
        for cf in high_cases {
            print(f"\n  [{cf.overall_risk_level}] {cf.provider_id}");
            print(f"    Billing     : {cf.billing_findings}");
            print(f"    Collusion   : {cf.collusion_findings}");
            print(f"    Patients    : {len(cf.patient_findings)} flagged");
            print(f"    Temporal    : {len(cf.temporal_findings)} anomalies");
            print(f"    Action      : {cf.recommended_action}");
            print(f"    Est. Fraud  : ${cf.estimated_fraud_amount:,.0f}");
            print(f"    Reasoning   : {cf.combined_reasoning[:300]}...");
        }
    }

    if med_cases {
        print(f"\n  ── MEDIUM RISK CASES ────────────────────────────────");
        for cf in med_cases {
            print(f"  [MEDIUM] {cf.provider_id} — {cf.recommended_action} "
                  f"(est. ${cf.estimated_fraud_amount:,.0f})");
        }
    }

    print("\n[synthesis] ─────────────────────────────────────────────");

    # ── JSON export for dashboard ─────────────────────────────────────────
    ::py::
    import json as _json, os as _os2

    _billing_map = {}
    for _f in billing_agent.findings:
        _billing_map[_f.provider_id] = {
            "risk_level": _f.risk_level,
            "anomalies": _f.anomalies,
            "reasoning": _f.reasoning,
        }

    _collusion_list = []
    for _r in collusion_agent.findings:
        _collusion_list.append({
            "physician_id": _r.physician_id,
            "connected_providers": _r.connected_providers,
            "fraud_providers_in_ring": _r.fraud_providers_in_ring,
            "non_fraud_providers_in_ring": _r.non_fraud_providers_in_ring,
            "shared_claim_count": _r.shared_claim_count,
            "total_ring_amount": _r.total_ring_amount,
            "risk_level": _r.risk_level,
            "reasoning": _r.reasoning,
        })

    _patient_list = []
    for _p in patient_agent.findings:
        _patient_list.append({
            "patient_id": _p.patient_id,
            "risk_level": _p.risk_level,
            "flags": _p.flags,
            "reasoning": _p.reasoning,
        })

    _temporal_list = []
    for _t in temporal_agent.findings:
        _temporal_list.append({
            "patient_id": _t.patient_id,
            "anomaly_type": _t.anomaly_type,
            "involved_providers": _t.involved_providers,
            "timeline_evidence": _t.timeline_evidence,
            "risk_level": _t.risk_level,
            "reasoning": _t.reasoning,
        })

    _providers_meta = {}
    for _pv in providers:
        _providers_meta[_pv["id"]] = {
            "fraud_label": _pv["fraud_label"],
            "total_claims": _pv.get("total_claims", 0) or 0,
            "total_amount": _pv.get("total_amount", 0.0) or 0.0,
        }

    _case_dicts = []
    for _cf in case_files:
        _case_dicts.append({
            "provider_id": _cf.provider_id,
            "overall_risk_level": _cf.overall_risk_level,
            "fraud_label": _providers_meta.get(_cf.provider_id, {}).get("fraud_label", "Unknown"),
            "total_claims": _providers_meta.get(_cf.provider_id, {}).get("total_claims", 0),
            "total_amount": _providers_meta.get(_cf.provider_id, {}).get("total_amount", 0.0),
            "billing_findings": _cf.billing_findings,
            "collusion_findings": _cf.collusion_findings,
            "patient_findings": _cf.patient_findings,
            "temporal_findings": _cf.temporal_findings,
            "combined_reasoning": _cf.combined_reasoning,
            "recommended_action": _cf.recommended_action,
            "estimated_fraud_amount": _cf.estimated_fraud_amount,
            "agent_signals": {
                "billing":   bool(provider_billing.get(_cf.provider_id)),
                "collusion": bool(provider_collusion.get(_cf.provider_id)),
                "patient":   bool(provider_patients.get(_cf.provider_id)),
                "temporal":  bool(provider_temporal.get(_cf.provider_id)),
            },
            "billing_detail": _billing_map.get(_cf.provider_id),
            "collusion_detail": [_r for _r in _collusion_list if _cf.provider_id in _r["connected_providers"]],
            "patient_detail":   [_p for _p in _patient_list if _cf.provider_id in pat_to_provs.get(_p["patient_id"], [])],
            "temporal_detail":  [_t for _t in _temporal_list if _cf.provider_id in pat_to_provs.get(_t["patient_id"], [])],
        })

    _high  = [c for c in _case_dicts if c["overall_risk_level"] == "HIGH"]
    _med   = [c for c in _case_dicts if c["overall_risk_level"] == "MEDIUM"]
    _fraud_total = sum(c["estimated_fraud_amount"] for c in _high)
    _collusion_rings = len(collusion_agent.findings)
    _temporal_anomalies = len(temporal_agent.findings)

    _output = {
        "meta": {
            "provider_count": len(providers),
            "case_count": len(_case_dicts),
            "high_risk_count": len(_high),
            "medium_risk_count": len(_med),
            "estimated_fraud_total": _fraud_total,
            "collusion_rings": _collusion_rings,
            "temporal_anomalies": _temporal_anomalies,
        },
        "case_files": _case_dicts,
        "collusion_rings": _collusion_list,
        "temporal_findings": _temporal_list,
        "providers_meta": _providers_meta,
    }

    _out_path = _os2.path.join(_proj_root, "output", "results.json")
    with open(_out_path, "w") as _fh:
        _json.dump(_output, _fh, indent=2)
    print(f"\n[synthesis] Results written to {_out_path}")
    ::py::
}
