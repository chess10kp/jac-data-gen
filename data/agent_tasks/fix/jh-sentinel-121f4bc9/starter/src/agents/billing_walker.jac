"""
Billing Volume Walker definitions — imported by billing_volume_agent.jac and synthesis_agent.jac.
No `with entry` block here so imports do not trigger side effects.
"""

include src.graph.schema;

obj FraudAssessment {
    has provider_id: str,
        risk_level: str,
        anomalies: list[str],
        reasoning: str;
}

def assess_billing(
    provider_id: str,
    total_claims: int,
    total_amount: float,
    inpatient_count: int,
    outpatient_count: int,
    avg_claim_amount: float,
    peer_avg_claims: float,
    peer_avg_amount: float,
    claims_ratio: float,
    amount_ratio: float,
    top_diagnosis_codes: list[str],
    sampled_claim_count: int,
    fraud_label: str,
) -> FraudAssessment {
    _risk:      str       = "LOW";
    _anomalies: list[str] = [];
    _reasoning: str       = "";
    ::py::
    if claims_ratio > 3.0:
        _anomalies.append(f"Very high claims ratio ({claims_ratio:.3f}) vs peer average (1.0) — possible phantom billing")
    elif claims_ratio > 1.5:
        _anomalies.append(f"High claims ratio ({claims_ratio:.3f}) compared to peer average (1.0)")
    if amount_ratio > 3.0:
        _anomalies.append(f"Very high amount ratio ({amount_ratio:.3f}) vs peer average (1.0) — possible upcoding")
    elif amount_ratio > 1.5:
        _anomalies.append(f"High amount ratio ({amount_ratio:.3f}) compared to peer average (1.0)")
    _unique = list(dict.fromkeys(top_diagnosis_codes))
    if len(_unique) <= 3 and (claims_ratio > 1.5 or amount_ratio > 1.5):
        _anomalies.append(f"Narrow set of diagnosis codes (top codes include {', '.join(_unique[:4])}) suggesting potential upcoding")
    if claims_ratio > 3.0 or amount_ratio > 3.0:
        _risk = "HIGH"
    elif claims_ratio > 1.5 or amount_ratio > 1.5:
        _risk = "MEDIUM"
    _reasoning = (
        f"Provider {provider_id} billed {total_claims} claims totalling ${total_amount:,.0f} "
        f"(claims_ratio={claims_ratio:.3f}x, amount_ratio={amount_ratio:.3f}x peer average, "
        f"avg ${avg_claim_amount:,.0f}/claim). "
        + (("Anomalies: " + "; ".join(_anomalies) + ".") if _anomalies else "No significant billing anomalies detected.")
    )
    ::py::
    return FraudAssessment(
        provider_id=provider_id,
        risk_level=_risk,
        anomalies=_anomalies,
        reasoning=_reasoning
    );
}

walker BillingVolumeAgent {
    has findings: list[FraudAssessment] = [],
        peer_avg_claims: float = 0.0,
        peer_avg_amount: float = 0.0,
        _prov_count: int = 0,
        _total_claims_sum: int = 0,
        _total_amount_sum: float = 0.0;

    can on_root with Root entry {
        for prov in [-->] {
            self._prov_count += 1;
            self._total_claims_sum += prov.total_claims;
            self._total_amount_sum += prov.total_amount;
        }
        if self._prov_count > 0 {
            self.peer_avg_claims = self._total_claims_sum / self._prov_count;
            self.peer_avg_amount = self._total_amount_sum / self._prov_count;
        }
        print(f"[billing] Peer group: {self._prov_count} providers, "
              f"avg_claims={self.peer_avg_claims:.0f}, "
              f"avg_amount=${self.peer_avg_amount:,.0f}");
        visit [-->];
    }

    can on_provider with Provider entry {
        diag_counts: dict = {};
        sampled_count = 0;
        for claim in [-->] {
            sampled_count += 1;
            for code in claim.diagnosis_codes {
                diag_counts[code] = diag_counts.get(code, 0) + 1;
            }
        }
        sorted_codes = sorted(diag_counts.keys(),
                              key=lambda k: diag_counts[k],
                              reverse=True);
        top_diag = sorted_codes[:5];

        avg_amt = 0.0;
        if here.total_claims > 0 {
            avg_amt = here.total_amount / here.total_claims;
        }

        claims_ratio = 0.0;
        amount_ratio = 0.0;
        if self.peer_avg_claims > 0.0 {
            claims_ratio = here.total_claims / self.peer_avg_claims;
        }
        if self.peer_avg_amount > 0.0 {
            amount_ratio = here.total_amount / self.peer_avg_amount;
        }
        max_ratio = claims_ratio;
        if amount_ratio > max_ratio {
            max_ratio = amount_ratio;
        }

        if max_ratio <= 1.5 {
            print(f"[billing] {here.id} skipped - within normal range "
                  f"(claims_ratio={claims_ratio:.2f}, amount_ratio={amount_ratio:.2f})");
        } else {
            print(f"[billing] Assessing {here.id} "
                  f"(claims={here.total_claims} [{claims_ratio:.1f}x], "
                  f"amount=${here.total_amount:,.0f} [{amount_ratio:.1f}x], "
                  f"label={here.fraud_label})...");

            assessment = assess_billing(
                provider_id         = here.id,
                total_claims        = here.total_claims,
                total_amount        = here.total_amount,
                inpatient_count     = here.inpatient_count,
                outpatient_count    = here.outpatient_count,
                avg_claim_amount    = avg_amt,
                peer_avg_claims     = self.peer_avg_claims,
                peer_avg_amount     = self.peer_avg_amount,
                claims_ratio        = claims_ratio,
                amount_ratio        = amount_ratio,
                top_diagnosis_codes = top_diag,
                sampled_claim_count = sampled_count,
                fraud_label         = here.fraud_label,
            );

            if assessment.risk_level == "HIGH" and max_ratio < 2.5 {
                assessment.risk_level = "MEDIUM";
            } elif assessment.risk_level == "LOW" and max_ratio >= 3.0 {
                assessment.risk_level = "MEDIUM";
            }

            self.findings.append(assessment);
            report assessment;
        }
    }
}
