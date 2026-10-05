"""
Vouch v2: Confidence Calibration Auditor
Analyzes action logs to detect classifier overconfidence/underconfidence
per intent category and recommends threshold adjustments.
"""

import from ._base { pass_result, confirm_result }

obj CalibrationResult {
    has intent_category: str;
    has total_actions: int;
    has mean_confidence: float;
    has overconfident_count: int;  # high confidence + user cancelled
    has underconfident_count: int; # low confidence + user confirmed
    has recommended_threshold: float;
    has is_miscalibrated: bool;
}

walker AuditCalibration {
    has action_log: list[dict] = [];
    # Each log entry: {intent, confidence, verdict, user_decision}
    has min_sample_size: int = 20;

    can audit with entry {
        # Group by intent category
        categories: dict = {};
        for log_entry in self.action_log {
            intent = log_entry.get("intent", "unknown");
            if intent not in categories {
                categories[intent] = [];
            }
            categories[intent].append(log_entry);
        }

        results: list[dict] = [];
        miscalibrated_intents: list[str] = [];

        for (intent, entries) in categories.items() {
            entries = entries as list[dict];
            if len(entries) < self.min_sample_size {
                continue;
            }

            total = len(entries);
            confidences = [e["confidence"] for e in entries];
            mean_conf = sum(confidences) / total;

            # Overconfident: high confidence but user cancelled
            overconfident = [e for e in entries
                           if e.get("confidence", 0) > 0.72
                           and e.get("user_decision") == "CANCELLED"];

            # Underconfident: low confidence but user confirmed
            underconfident = [e for e in entries
                            if e.get("confidence", 0) < 0.72
                            and e.get("user_decision") == "CONFIRMED"];

            oc_rate = len(overconfident) / total if total > 0 else 0;
            uc_rate = len(underconfident) / total if total > 0 else 0;

            is_miscalibrated = oc_rate > 0.15 or uc_rate > 0.15;

            # Recommend threshold based on actual decision data
            confirmed = [e["confidence"] for e in entries if e.get("user_decision") == "CONFIRMED"];
            cancelled = [e["confidence"] for e in entries if e.get("user_decision") == "CANCELLED"];

            if cancelled {
                recommended = max(cancelled) + 0.05;
            } elif confirmed {
                recommended = min(confirmed) - 0.05;
            } else {
                recommended = 0.72;
            }

            recommended = max(0.3, min(0.95, recommended));

            if is_miscalibrated {
                miscalibrated_intents.append(intent);
            }

            results.append({
                "intent": intent,
                "total": total,
                "mean_confidence": round(mean_conf, 3),
                "overconfident": len(overconfident),
                "underconfident": len(underconfident),
                "recommended_threshold": round(recommended, 2),
                "miscalibrated": is_miscalibrated
            });
        }

        if miscalibrated_intents {
            report confirm_result(
                "confidence_calibrator",
                f"Calibration issues detected in {len(miscalibrated_intents)} intent(s): {', '.join(miscalibrated_intents)}. Run `vouch report --calibration` for details."
            );
        } else {
            report pass_result("confidence_calibrator");
        }
    }
}
