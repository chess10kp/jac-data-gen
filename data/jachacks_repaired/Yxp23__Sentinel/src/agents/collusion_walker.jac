"""
Collusion Walker definitions — imported by collusion_agent.jac and synthesis_agent.jac.
No `with entry` block here so imports do not trigger side effects.
"""

include src.graph.schema;

obj CollusionRing {
    has physician_id: str,
        connected_providers: list[str],
        fraud_providers_in_ring: list[str],
        non_fraud_providers_in_ring: list[str],
        shared_claim_count: int,
        total_ring_amount: float,
        risk_level: str,
        reasoning: str;
}

def assess_collusion(
    physician_id: str,
    connected_providers: list[str],
    fraud_providers_in_ring: list[str],
    non_fraud_providers_in_ring: list[str],
    shared_claim_count: int,
    total_ring_amount: float,
    provider_details: list[dict]
) -> CollusionRing {
    _risk:      str = "LOW";
    _reasoning: str = "";
    ::py::
    _fc = len(fraud_providers_in_ring)
    _tc = len(connected_providers)
    _ff = _fc / _tc if _tc > 0 else 0.0
    if _tc >= 3 and _ff > 0.5 and total_ring_amount > 50000:
        _risk = "HIGH"
    elif _fc >= 2 or (total_ring_amount > 20000 and _fc >= 1):
        _risk = "MEDIUM"
    _reasoning = (
        f"Physician {physician_id} appears on claims from {_tc} provider(s) "
        f"({_fc} fraud-labeled, {len(non_fraud_providers_in_ring)} non-fraud). "
        f"Total ring amount: ${total_ring_amount:,.0f}, shared claim count: {shared_claim_count}. "
        + (f"Fraud fraction {_ff:.0%} and high dollar flow indicate coordinated billing." if _risk == "HIGH"
           else "Partial fraud overlap warrants monitoring." if _risk == "MEDIUM"
           else "Pattern consistent with legitimate group practice.")
    )
    ::py::
    return CollusionRing(
        physician_id=physician_id,
        connected_providers=connected_providers,
        fraud_providers_in_ring=fraud_providers_in_ring,
        non_fraud_providers_in_ring=non_fraud_providers_in_ring,
        shared_claim_count=shared_claim_count,
        total_ring_amount=total_ring_amount,
        risk_level=_risk,
        reasoning=_reasoning
    );
}

walker CollusionAgent {
    has phys_to_providers: dict = {},
        phys_claim_counts: dict = {},
        phys_amounts: dict = {},
        provider_info: dict = {},
        findings: list[CollusionRing] = [];

    can on_root with Root entry {
        for prov in [-->] {
            self.provider_info[prov.id] = {
                "id": prov.id,
                "fraud_label": prov.fraud_label,
                "total_claims": prov.total_claims,
                "total_amount": prov.total_amount
            };

            for claim in [prov -->] {
                for phys in [claim -->] {
                    if phys.id not in self.phys_to_providers {
                        self.phys_to_providers[phys.id] = [];
                        self.phys_claim_counts[phys.id] = 0;
                        self.phys_amounts[phys.id] = 0.0;
                    }
                    if prov.id not in self.phys_to_providers[phys.id] {
                        self.phys_to_providers[phys.id].append(prov.id);
                    }
                    self.phys_claim_counts[phys.id] += 1;
                    self.phys_amounts[phys.id] += claim.amount;
                }
            }
        }

        print(f"[collusion] Mapped {len(self.phys_to_providers)} physicians to providers");

        shared_physicians = [];
        for phys_id in self.phys_to_providers {
            providers_list = self.phys_to_providers[phys_id];
            if len(providers_list) >= 2 {
                shared_physicians.append(phys_id);
            }
        }

        print(f"[collusion] Found {len(shared_physicians)} physicians shared between 2+ providers\n");

        for phys_id in shared_physicians {
            providers_list = self.phys_to_providers[phys_id];
            claim_count = self.phys_claim_counts[phys_id];
            total_amount = self.phys_amounts[phys_id];

            fraud_provs = [];
            non_fraud_provs = [];
            details = [];
            for pid in providers_list {
                info = self.provider_info[pid];
                details.append(info);
                if info["fraud_label"] == "Yes" {
                    fraud_provs.append(pid);
                } else {
                    non_fraud_provs.append(pid);
                }
            }

            if len(fraud_provs) > 0 {
                print(f"[collusion] Assessing physician {phys_id} "
                      f"(shared by {len(providers_list)} providers, "
                      f"{len(fraud_provs)} fraud, "
                      f"${total_amount:,.0f} total)...");

                ring = assess_collusion(
                    physician_id=phys_id,
                    connected_providers=providers_list,
                    fraud_providers_in_ring=fraud_provs,
                    non_fraud_providers_in_ring=non_fraud_provs,
                    shared_claim_count=claim_count,
                    total_ring_amount=total_amount,
                    provider_details=details
                );

                fraud_fraction = len(fraud_provs) / len(providers_list);
                if ring.risk_level == "HIGH" and (fraud_fraction < 0.5 or total_amount < 50000.0) {
                    ring.risk_level = "MEDIUM";
                } elif ring.risk_level == "MEDIUM" and fraud_fraction == 0.0 {
                    ring.risk_level = "LOW";
                }

                self.findings.append(ring);

                print(f"  → risk={ring.risk_level}, "
                      f"reasoning={ring.reasoning[:150]}...\n");
            }
        }
    }
}
