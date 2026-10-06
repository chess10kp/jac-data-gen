"""Scam detection pipeline — analyzes transactions for elder financial abuse patterns."""

import from graph.nodes.patient { Patient }
import from graph.nodes.transaction { Transaction }
import from graph.nodes.scam_alert { ScamAlert }
import from abilities.llm_abilities { analyze_scam_risk }
import from types.financial_types { SCAM_INDICATORS, HIGH_VALUE_THRESHOLDS }

import from datetime { datetime }
import from uuid { uuid4 }

walker ScamDetectionPipeline {
    has patient_name: str = "",
        scam_count: int = 0;

    can start with Patient entry {
        self.patient_name = str(getattr(here, "name", ""));
        self.scam_count = 0;
        visit [-->];
    }

    can analyze_transaction with Transaction entry {
        amount   = float(getattr(here, "amount", 0.0) or 0.0);
        merchant = str(getattr(here, "merchant_name", ""));
        txn_date = str(getattr(here, "date", ""));

        if amount <= 0 {
            disengage;
        }

        risk_score: float = 0.0;
        risk_flags: list = [];

        # Flag 1: High-value single transaction
        if amount >= HIGH_VALUE_THRESHOLDS["single_transaction"] {
            risk_score += 0.3;
            risk_flags.append(f"Large transaction: ${amount:,.2f}");
        }

        # Flag 2: Scam keyword in merchant name
        desc_lower = merchant.lower();
        for keyword in SCAM_INDICATORS {
            if keyword in desc_lower {
                risk_score += 0.4;
                risk_flags.append(f"Suspicious keyword: '{keyword}'");
                break;
            }
        }

        # Flag 3: LLM scam risk analysis for high-risk transactions
        if risk_score >= 0.3 {
            llm_result = analyze_scam_risk(
                transaction_description=merchant,
                amount=amount,
                merchant=merchant,
                risk_flags=risk_flags
            );
            llm_assessment: dict = dict(llm_result);
            if bool(llm_assessment.get("is_suspicious", False)) {
                conf: float = float(llm_assessment.get("confidence", risk_score) or risk_score);
                risk_score = max(risk_score, conf);
                flags_extra: list = list(llm_assessment.get("additional_flags", []));
                risk_flags.extend(flags_extra);
            }
        }

        # Create ScamAlert if risk threshold exceeded
        if risk_score >= 0.5 {
            alert = ScamAlert(
                alert_id=str(uuid4()),
                confidence_score=risk_score,
                evidence=risk_flags,
                amount_at_risk=amount,
                description=f"Suspicious transaction to {merchant} on {txn_date}",
                resolution="OPEN",
                detected_at=str(datetime.utcnow())
            );
            here ++> alert;
            self.scam_count += 1;
            print(f"[ScamDetection] Alert created: risk={risk_score:.2f} for ${amount:,.2f} to {merchant}");
        }
    }

    can finish with Patient entry {
        if self.scam_count > 0 {
            print(f"[ScamDetection] {self.scam_count} potential scam(s) flagged for {self.patient_name}");
        }
        report {"patient": self.patient_name, "scam_alerts": self.scam_count};
    }
}
