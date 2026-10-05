"""
Patient Pattern Walker definitions — imported by patient_agent.jac and synthesis_agent.jac.
No `with entry` block here so imports do not trigger side effects.
"""

include src.graph.schema;

obj PatientFinding {
    has patient_id: str,
        risk_level: str,
        flags: list[str],
        reasoning: str;
}

obj PatientAssessment {
    has risk_level: str,
        reasoning: str;
}

def assess_patient(
    patient_id: str,
    provider_count: int,
    unique_providers: list[str],
    claim_count: int,
    total_amount: float,
    avg_claim_amount: float,
    deceased: bool,
    has_post_death_claim: bool,
    dod: str,
    latest_claim_date: str,
    provider_fraud_labels: list[str],
    fraud_provider_count: int,
    observed_flags: list[str],
) -> PatientAssessment {
    _risk:      str = "LOW";
    _reasoning: str = "";
    ::py::
    _flags_txt = ", ".join(observed_flags) if observed_flags else "none"
    if has_post_death_claim:
        _risk = "HIGH"
        _reasoning = (
            f"Patient {patient_id} has post-death claims (DOD: {dod}, latest claim: {latest_claim_date}). "
            "Billing after recorded death is definitive fraud."
        )
    elif fraud_provider_count >= 3 and total_amount > 10000:
        _risk = "HIGH"
        _reasoning = (
            f"Patient {patient_id} billed by {fraud_provider_count} fraud-labeled providers "
            f"(${total_amount:,.0f} total). Flags: {_flags_txt}."
        )
    elif provider_count >= 4:
        _risk = "HIGH"
        _reasoning = (
            f"Patient {patient_id} appears at {provider_count} different providers "
            f"(${total_amount:,.0f} total, {claim_count} claims). Flags: {_flags_txt}."
        )
    elif (fraud_provider_count >= 2 and 2000 <= total_amount <= 10000) or \
         (claim_count >= 10 and fraud_provider_count >= 1) or (provider_count >= 3):
        _risk = "MEDIUM"
        _reasoning = (
            f"Patient {patient_id}: {fraud_provider_count} fraud provider(s) out of {provider_count} total, "
            f"${total_amount:,.0f} billed, {claim_count} claims. Flags: {_flags_txt}."
        )
    else:
        _risk = "LOW"
        _reasoning = (
            f"Patient {patient_id}: limited fraud overlap ({fraud_provider_count} fraud providers), "
            f"${total_amount:,.0f} total. Borderline flags: {_flags_txt}."
        )
    ::py::
    return PatientAssessment(risk_level=_risk, reasoning=_reasoning);
}

walker PatientPatternAgent {
    has deceased_lookup: dict = {},
        provider_fraud: dict = {},
        findings: list[PatientFinding] = [];

    can on_root with Root entry {
        pat_providers: dict = {};
        pat_claim_counts: dict = {};
        pat_amounts: dict = {};
        pat_dates: dict = {};

        for prov in [-->] {
            self.provider_fraud[prov.id] = prov.fraud_label;

            for claim in [prov -->] {
                bene = claim.bene_id;

                if bene not in pat_providers {
                    pat_providers[bene] = [];
                    pat_claim_counts[bene] = 0;
                    pat_amounts[bene] = 0.0;
                    pat_dates[bene] = [];
                }

                if prov.id not in pat_providers[bene] {
                    pat_providers[bene].append(prov.id);
                }
                pat_claim_counts[bene] += 1;
                pat_amounts[bene] += claim.amount;
                if claim.claim_start {
                    pat_dates[bene].append(claim.claim_start);
                }
            }
        }

        print(f"[patient] Collected stats for {len(pat_providers)} patients\n");

        assessed = 0;
        skipped = 0;

        for bene in pat_providers {
            provider_list  = pat_providers[bene];
            claim_cnt      = pat_claim_counts[bene];
            total_amt      = pat_amounts[bene];
            dates          = pat_dates[bene];
            prov_count     = len(provider_list);

            fraud_prov_count = 0;
            fraud_labels = [];
            for pid in provider_list {
                lbl = self.provider_fraud.get(pid, "No");
                fraud_labels.append(lbl);
                if lbl == "Yes" {
                    fraud_prov_count += 1;
                }
            }

            deceased   = False;
            dod_str    = "";
            post_death = False;
            pat_info   = self.deceased_lookup.get(bene, {});
            if pat_info {
                deceased = pat_info.get("deceased", False);
                dod_str  = pat_info.get("dod", "") or "";
                if deceased and dod_str and dates {
                    latest = max(dates);
                    if latest > dod_str {
                        post_death = True;
                    }
                }
            }

            computed_flags: list[str] = [];
            if prov_count >= 3 {
                computed_flags.append("multi_provider");
            }
            if claim_cnt >= 10 {
                computed_flags.append("high_volume");
            }
            if post_death {
                computed_flags.append("post_death_claim");
            }
            if fraud_prov_count >= 2 {
                computed_flags.append("fraud_provider_overlap");
            }

            if not computed_flags {
                skipped += 1;
                continue;
            }

            avg_claim_amt = 0.0;
            if claim_cnt > 0 {
                avg_claim_amt = total_amt / claim_cnt;
            }

            latest_date = "";
            if dates {
                latest_date = max(dates);
            }

            print(f"[patient] Assessing {bene} "
                  f"(providers={prov_count}, claims={claim_cnt}, "
                  f"amount=${total_amt:,.0f}, flags={computed_flags})...");

            llm_out = assess_patient(
                patient_id           = bene,
                provider_count       = prov_count,
                unique_providers     = provider_list,
                claim_count          = claim_cnt,
                total_amount         = total_amt,
                avg_claim_amount     = avg_claim_amt,
                deceased             = deceased,
                has_post_death_claim = post_death,
                dod                  = dod_str,
                latest_claim_date    = latest_date,
                provider_fraud_labels = fraud_labels,
                fraud_provider_count = fraud_prov_count,
                observed_flags       = computed_flags,
            );

            final_risk = llm_out.risk_level;
            if post_death {
                final_risk = "HIGH";
            } elif final_risk == "HIGH" and total_amt < 2000.0 {
                final_risk = "MEDIUM";
            } elif final_risk == "HIGH" and prov_count == 2 and fraud_prov_count == 2 and total_amt < 10000.0 {
                final_risk = "MEDIUM";
            }

            finding = PatientFinding(
                patient_id = bene,
                risk_level = final_risk,
                flags      = computed_flags,
                reasoning  = llm_out.reasoning,
            );

            self.findings.append(finding);
            assessed += 1;
            report finding;

            print(f"  → risk={finding.risk_level}, flags={finding.flags}\n");
        }

        print(f"[patient] Assessed: {assessed}, skipped: {skipped}");
    }
}
