"""
PayGuard Jac Core Logic

This file ports the same behavior currently implemented in Python:
1) deterministic planning
2) tool-style signal extraction
3) weighted risk scoring
4) explainable decision output
"""

obj Transaction {
    has scenario: str;
    has txn_id: str;
    has user_id: str;
    has merchant_id: str;
    has amount: float;
    has country: str;
    has timestamp: str;
}

obj UserProfile {
    has home_country: str;
    has avg_amount: float;
    has account_age_days: int;
}

obj InvestigationResult {
    has scenario: str;
    has txn_id: str;
    has user_id: str;
    has plan: list;
    has observations: dict;
    has risk_score: int;
    has decision: str;
    has confidence: float;
    has reasons: list;
    has investigation_log: list;
    has timestamp: str;
}

walker FraudInvestigator {
    has tx: Transaction;
    has profile: UserProfile;
    has prior_cases: list;

    can run with entry {
        plan = self.plan_checks();
        log = ["PLAN: " + ", ".join(plan)];
        observations = self.call_tools(plan=plan, log=log);
        scored = self.score(observations=observations);

        decision = self.decide(score=scored["score"]);
        confidence = self.confidence(score=scored["score"]);
        log.append("DECISION score=" + str(scored["score"]) + " -> " + decision);

        result = InvestigationResult(
            scenario=self.tx.scenario,
            txn_id=self.tx.txn_id,
            user_id=self.tx.user_id,
            plan=plan,
            observations=observations,
            risk_score=scored["score"],
            decision=decision,
            confidence=confidence,
            reasons=scored["reasons"][0:3],
            investigation_log=log,
            timestamp=self.tx.timestamp,
        );

        report result;
    }

    can plan_checks {
        checks = ["user_profile", "velocity", "merchant_risk", "amount_outlier"];
        if self.tx.amount > 5000 {
            checks.append("location_mismatch");
        }
        return checks;
    }

    can call_tools(plan: list, log: list) {
        obs = {};

        if "user_profile" in plan {
            obs["account_age_days"] = self.profile.account_age_days;
            log.append(
                "TOOL user_profile -> account_age_days="
                + str(self.profile.account_age_days)
                + ", avg_amount="
                + str(self.profile.avg_amount)
                + ", home_country="
                + self.profile.home_country
            );
        }

        if "velocity" in plan {
            obs["velocity_60m"] = self.velocity_count(window_minutes=60) + 1;
            log.append("TOOL velocity -> velocity_60m=" + str(obs["velocity_60m"]));
        }

        if "merchant_risk" in plan {
            obs["merchant_risk"] = self.merchant_risk_level();
            log.append("TOOL merchant_risk -> merchant_risk=" + obs["merchant_risk"]);
        }

        if "amount_outlier" in plan {
            obs["amount_outlier"] = self.tx.amount > (self.profile.avg_amount * 3.0);
            log.append("TOOL amount_outlier -> amount_outlier=" + str(obs["amount_outlier"]));
        }

        if "location_mismatch" in plan {
            obs["location_mismatch"] = self.tx.country != self.profile.home_country;
            log.append("TOOL location_mismatch -> location_mismatch=" + str(obs["location_mismatch"]));
        }

        obs["prior_fraud_rate"] = self.prior_fraud_rate();
        log.append("MEMORY prior_fraud_rate -> " + str(obs["prior_fraud_rate"]));

        return obs;
    }

    can score(observations: dict) {
        score = 0;
        reasons = [];

        if observations.get("velocity_60m", 0) >= 3 {
            score += 30;
            reasons.append("High transaction velocity in last 60 minutes");
        }

        risk = observations.get("merchant_risk", "medium");
        if risk == "high" {
            score += 30;
            reasons.append("High-risk merchant");
        } elif risk == "medium" {
            score += 15;
            reasons.append("Medium-risk merchant");
        }

        if observations.get("amount_outlier", false) {
            score += 25;
            reasons.append("Amount is high compared to user average");
        }

        if observations.get("location_mismatch", false) {
            score += 20;
            reasons.append("Transaction location differs from home country");
        }

        if observations.get("account_age_days", 9999) < 30 {
            score += 10;
            reasons.append("New account has higher uncertainty");
        }

        if observations.get("prior_fraud_rate", 0.0) >= 0.5 {
            score += 10;
            reasons.append("User has risky prior outcomes");
        }

        if score > 100 {
            score = 100;
        }

        return {"score": score, "reasons": reasons};
    }

    can decide(score: int) {
        if score >= 70 {
            return "BLOCK";
        }
        if score >= 40 {
            return "ESCALATE";
        }
        return "ALLOW";
    }

    can confidence(score: int) {
        return round(0.5 + (score / 200.0), 2);
    }

    # Integration hooks to wire with real storage/tool modules in Jaseci runtime.
    can velocity_count(window_minutes: int) {
        return 0;
    }

    can merchant_risk_level {
        return "medium";
    }

    can prior_fraud_rate {
        return 0.0;
    }
}
