"""
FraudGraph - Agentic Fraud Detection Engine
Core Jac file: walkers, nodes, and by llm() reasoning.

Architecture:
  Nodes:
    - AccountNode     : a user/account entity
    - TransactionNode : a single transaction
    - MerchantNode    : a merchant entity
    - FraudCaseNode   : a confirmed/suspected fraud case

  Walkers:
    - FraudDetectionWalker  : traverses account->transactions, scores each tx
    - AnomalyPatternWalker  : detects velocity, geo, merchant anomalies
    - EscalationWalker      : routes high-risk cases, uses by llm() for action
    - SynthesisWalker       : aggregates findings, produces executive report
"""

import from fraud_tools { score_transaction, detect_velocity_anomaly, get_merchant_risk, flag_geo_anomaly }
import from datetime { datetime }

# ─────────────────────────────────────────────
# GRAPH NODES
# ─────────────────────────────────────────────

node AccountNode {
    has account_id: str;
    has user_name: str;
    has account_age_days: int;
    has avg_monthly_spend: float;
    has home_country: str;
    has risk_tier: str = "low";
    has flagged: bool = False;
    has fraud_score: float = 0.0;
    has last_scan: str = "";
}

node TransactionNode {
    has tx_id: str;
    has amount: float;
    has merchant: str;
    has merchant_category: str;
    has country: str;
    has timestamp: str;
    has device_fingerprint: str;
    has ip_address: str;
    has is_flagged: bool = False;
    has fraud_probability: float = 0.0;
    has anomaly_reasons: list = [];
}

node MerchantNode {
    has merchant_id: str;
    has merchant_name: str;
    has category: str;
    has country: str;
    has fraud_rate: float = 0.0;
    has transaction_volume: int = 0;
}

node FraudCaseNode {
    has case_id: str;
    has account_id: str;
    has tx_ids: list;
    has severity: str;
    has reason_summary: str;
    has recommended_action: str;
    has status: str = "open";
    has assigned_to: str = "auto";
    has created_at: str = "";
}

# ─────────────────────────────────────────────
# EDGES
# ─────────────────────────────────────────────

edge has_transaction {}
edge belongs_to_merchant {}
edge linked_case {}

# ─────────────────────────────────────────────
# WALKER 1: FraudDetectionWalker
# Traverses account -> transactions, ML-scores each tx
# ─────────────────────────────────────────────

walker FraudDetectionWalker {
    has account_id: str;
    has flagged_transactions: list = [];
    has total_fraud_score: float = 0.0;
    has tx_count: int = 0;

    can start_detection with AccountNode entry {
        here.last_scan = str(datetime.utcnow());
        visit [-->[?:TransactionNode]];
    }

    can score_tx with TransactionNode entry {
        self.tx_count += 1;

        score_result = score_transaction({
            "tx_id": here.tx_id,
            "amount": here.amount,
            "merchant": here.merchant,
            "merchant_category": here.merchant_category,
            "country": here.country,
            "timestamp": here.timestamp,
            "device_fingerprint": here.device_fingerprint,
            "ip_address": here.ip_address,
        });

        here.fraud_probability = score_result["fraud_probability"];
        here.anomaly_reasons = score_result["reasons"];

        if here.fraud_probability > 0.6 {
            here.is_flagged = True;
            self.flagged_transactions.append({
                "tx_id": here.tx_id,
                "amount": here.amount,
                "merchant": here.merchant,
                "fraud_probability": here.fraud_probability,
                "reasons": here.anomaly_reasons,
            });
        }

        self.total_fraud_score += here.fraud_probability;
    }

    can finalize with AccountNode exit {
        avg = self.total_fraud_score / self.tx_count if self.tx_count > 0 else 0.0;
        here.fraud_score = round(avg * 100, 2);

        if here.fraud_score > 75 {
            here.risk_tier = "critical";
            here.flagged = True;
        } elif here.fraud_score > 50 {
            here.risk_tier = "high";
            here.flagged = True;
        } elif here.fraud_score > 25 {
            here.risk_tier = "medium";
        } else {
            here.risk_tier = "low";
        }

        report {
            "account_id": here.account_id,
            "fraud_score": here.fraud_score,
            "risk_tier": here.risk_tier,
            "flagged_transactions": self.flagged_transactions,
            "tx_scanned": self.tx_count,
        };
    }
}

# ─────────────────────────────────────────────
# WALKER 2: AnomalyPatternWalker
# Detects velocity, geo, and merchant anomalies
# ─────────────────────────────────────────────

walker AnomalyPatternWalker {
    has account_id: str;
    has recent_tx_window: int = 24;
    has patterns_found: list = [];

    can detect_patterns with AccountNode entry {
        recent_txs = [-->[?:TransactionNode]];

        velocity_result = detect_velocity_anomaly(
            account_id=here.account_id,
            tx_count=len(recent_txs),
            window_hours=self.recent_tx_window
        );

        if velocity_result["is_anomaly"] {
            self.patterns_found.append({
                "pattern": "velocity_anomaly",
                "severity": velocity_result["severity"],
                "detail": velocity_result["detail"],
            });
        }

        visit [-->[?:TransactionNode]];
    }

    can check_geo with TransactionNode entry {
        geo_result = flag_geo_anomaly(
            tx_country=here.country,
            account_id=self.account_id,
        );

        if geo_result["is_anomaly"] {
            here.anomaly_reasons.append("geo_anomaly: " + geo_result["detail"]);
            self.patterns_found.append({
                "pattern": "geo_anomaly",
                "tx_id": here.tx_id,
                "detail": geo_result["detail"],
                "severity": "high",
            });
        }

        merchant_risk = get_merchant_risk(here.merchant, here.merchant_category);
        if merchant_risk["risk_score"] > 0.7 {
            self.patterns_found.append({
                "pattern": "high_risk_merchant",
                "tx_id": here.tx_id,
                "merchant": here.merchant,
                "merchant_risk": merchant_risk["risk_score"],
                "severity": "medium",
            });
        }
    }

    can summarize with AccountNode exit {
        report {
            "account_id": self.account_id,
            "patterns": self.patterns_found,
            "pattern_count": len(self.patterns_found),
        };
    }
}

# ─────────────────────────────────────────────
# WALKER 3: EscalationWalker
# Routes high-risk accounts; uses by llm() for recommended action
# ─────────────────────────────────────────────

walker EscalationWalker {
    has escalated: list = [];

    can evaluate with AccountNode entry {
        if here.risk_tier in ["high", "critical"] {
            action = self.recommend_action(
                risk_tier=here.risk_tier,
                fraud_score=here.fraud_score,
                account_age_days=here.account_age_days,
            );

            flagged_tx_ids: list = [];
            for tx in [-->[?:TransactionNode]] {
                if tx.is_flagged {
                    flagged_tx_ids.append(tx.tx_id);
                }
            }

            new_case = FraudCaseNode(
                case_id="CASE-" + here.account_id + "-" + str(datetime.utcnow().timestamp()),
                account_id=here.account_id,
                tx_ids=flagged_tx_ids,
                severity=here.risk_tier,
                reason_summary=action["reason"],
                recommended_action=action["action"],
                status="open",
                assigned_to="human_review" if here.risk_tier == "critical" else "auto",
                created_at=str(datetime.utcnow()),
            );

            here +>:linked_case:+> new_case;
            self.escalated.append(new_case.case_id);
        }
    }

    # ── by llm() call: LLM decides the right action ──────────────────────────
    def recommend_action(risk_tier: str, fraud_score: float, account_age_days: int) -> dict
        by llm(temperature=0.2);

    can report_escalations with Root exit {
        report {
            "escalated_cases": self.escalated,
            "count": len(self.escalated),
        };
    }
}

# ─────────────────────────────────────────────
# WALKER 4: SynthesisWalker
# Aggregates all flagged accounts, produces executive report via by llm()
# ─────────────────────────────────────────────

walker SynthesisWalker {
    has scan_id: str;
    has all_findings: list = [];
    has total_accounts: int = 0;

    can collect with AccountNode entry {
        self.total_accounts += 1;
        if here.flagged {
            flagged_count: int = 0;
            for tx in [-->[?:TransactionNode]] {
                if tx.is_flagged {
                    flagged_count += 1;
                }
            }
            self.all_findings.append({
                "account_id": here.account_id,
                "user_name": here.user_name,
                "fraud_score": here.fraud_score,
                "risk_tier": here.risk_tier,
                "flagged_tx_count": flagged_count,
            });
        }
    }

    # ── by llm() call: LLM writes the executive summary ──────────────────────
    def produce_report() -> dict by llm(temperature=0.1);

    can finalize with Root exit {
        report self.produce_report();
    }
}

sem EscalationWalker.recommend_action = """
You are a senior fraud analyst AI. Given the fraud risk tier, score,
and account age (in days), recommend the most appropriate action.
Return a dict with exactly two keys:
  'reason': a one-sentence explanation of why this account is risky
  'action': one of [block_account, freeze_card, request_verification,
                    flag_for_review, reduce_limit, monitor_only]
Be concise and decisive.
""";

sem SynthesisWalker.produce_report = """
You are a senior fraud analyst AI. Given self.all_findings (list of
flagged accounts with fraud_score and risk_tier) and self.total_accounts,
produce a concise executive summary report as a JSON dict with keys:
  summary (str): 2-3 sentence overview
  critical_count (int): number of critical-tier accounts
  high_count (int): number of high-tier accounts
  top_patterns (list[str]): top 3 observed fraud patterns
  immediate_actions (list[str]): top 3 recommended actions
""";
