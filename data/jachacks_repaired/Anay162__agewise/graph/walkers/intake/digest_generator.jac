"""DigestGenerator walker — creates weekly digest for the adult child.

Walks the entire patient graph, aggregates all activity into a single
comprehensive Digest node using by llm(), then queues it for delivery.

Covers: documents, claims, disputes, appointments, medications/refills,
care gaps, benefits eligibility, recurring bills, scam alerts.
"""

import from graph.nodes.patient { Patient }
import from graph.nodes.document { Document }
import from graph.nodes.claim { Claim }
import from graph.nodes.dispute { Dispute }
import from graph.nodes.notification { Notification }
import from graph.nodes.digest { Digest }
import from graph.nodes.scam_alert { ScamAlert }
import from graph.nodes.appointment { Appointment }
import from graph.nodes.prescription { Prescription }
import from graph.nodes.medication { Medication }
import from graph.nodes.care_gap { CareGap }
import from graph.nodes.benefits_eligibility { BenefitsEligibility }
import from graph.nodes.recurring_bill { RecurringBill }
import from abilities.llm_abilities { generate_weekly_digest }

import from datetime { datetime, timedelta }
import from uuid { uuid4 }


walker DigestGenerator {
    has period_days: int = 7;

    can start with Patient entry {
        period_end = datetime.utcnow();
        period_start = period_end - timedelta(days=self.period_days);
        ps = period_start.isoformat();
        pe = period_end.isoformat();

        # --- Documents ---
        new_docs = [
            {
                "id": d.doc_id,
                "type": d.classification,
                "summary": d.plain_english_summary[:200] if d.plain_english_summary else ""
            }
            for d in [n for n in [here-->] if isinstance(n, Document)]
            if d.ingested_at and d.ingested_at >= ps
        ];

        # --- Claims ---
        claims = [
            {
                "number": c.claim_number,
                "date": c.service_date_start,
                "amount": c.total_charges,
                "status": c.status
            }
            for c in [n for n in [here-->] if isinstance(n, Claim)]
            if c.created_at and c.created_at >= ps
        ];

        # --- Open Disputes ---
        all_disputes = [];
        for claim in [n for n in [here-->] if isinstance(n, Claim)] {
            for item in [n for n in [claim-->]] {
                for d in [n for n in [item-->] if isinstance(n, Dispute)] {
                    if d.status in ["OPEN", "IN_PROGRESS", "APPEALED"] {
                        all_disputes.append({
                            "id": d.dispute_id,
                            "type": d.error_type,
                            "amount": d.amount_disputed,
                            "severity": d.severity,
                            "status": d.status,
                            "deadline": d.deadline
                        });
                    }
                }
            }
        }

        pending_actions = [
            {"type": d["type"], "amount": d["amount"], "deadline": d["deadline"]}
            for d in all_disputes
            if d.get("deadline")
        ];

        # --- Scam Alerts ---
        scam_alerts = [
            {"type": s.threat_type, "confidence": s.confidence_score, "amount": s.amount_at_risk}
            for s in [n for n in [here-->] if isinstance(n, ScamAlert)]
            if s.resolution == "OPEN"
        ];

        # --- Upcoming Appointments (next 14 days) ---
        today_str = datetime.utcnow().strftime("%Y-%m-%d");
        two_weeks = (datetime.utcnow() + timedelta(days=14)).strftime("%Y-%m-%d");
        upcoming_appointments = [
            {
                "provider": a.provider_name,
                "specialty": a.specialty,
                "date": a.appointment_date,
                "time": a.appointment_time,
                "location": a.facility_name,
                "purpose": a.purpose
            }
            for a in [n for n in [here-->] if isinstance(n, Appointment)]
            if a.status == "SCHEDULED"
            and a.appointment_date
            and today_str <= a.appointment_date <= two_weeks
        ];

        # --- Medications Due for Refill (within 14 days) ---
        refills_due = [];
        for rx in [n for n in [here-->] if isinstance(n, Prescription)] {
            if rx.status != "ACTIVE" or not rx.fill_date {
                continue;
            }
            try {
                filled = datetime.strptime(rx.fill_date, "%Y-%m-%d");
                due = filled + timedelta(days=rx.days_supply);
                days_left = (due - datetime.utcnow()).days;
                if days_left <= 14 {
                    refills_due.append({
                        "drug": rx.drug_name,
                        "days_until_refill": days_left,
                        "refills_remaining": rx.refills_remaining,
                        "pharmacy": rx.pharmacy_name
                    });
                }
            } except Exception {
                continue;
            }
        }

        # Also check Medication nodes if built
        for med in [n for n in [here-->] if isinstance(n, Medication)] {
            if med.active and med.days_until_refill is not None and med.days_until_refill <= 14 {
                already = any(r["drug"] == med.drug_name for r in refills_due);
                if not already {
                    refills_due.append({
                        "drug": med.drug_name,
                        "days_until_refill": med.days_until_refill,
                        "refills_remaining": med.refills_remaining,
                        "pharmacy": med.pharmacy_name
                    });
                }
            }
        }

        # --- Care Gaps ---
        care_gaps = [
            {
                "type": g.gap_type,
                "specialty": g.specialty_needed,
                "last_visit": g.last_visit_date,
                "urgency": g.urgency
            }
            for g in [n for n in [here-->] if isinstance(n, CareGap)]
            if not g.resolved
        ];

        # --- Benefits Found ---
        benefits_found = [
            {
                "program": b.program_name,
                "eligible": b.is_eligible,
                "monthly_savings": b.estimated_savings_monthly,
                "url": b.application_url
            }
            for b in [n for n in [here-->] if isinstance(n, BenefitsEligibility)]
            if b.is_eligible
        ];

        # --- Overdue / Upcoming Bills ---
        overdue_bills = [
            {
                "biller": b.biller_name,
                "amount": b.average_amount,
                "status": b.status,
                "last_paid": b.last_payment_date
            }
            for b in [n for n in [here-->] if isinstance(n, RecurringBill)]
            if b.status in ["overdue", "missed"]
        ];

        # --- Build activity summary dict ---
        activity = {
            "new_documents": new_docs,
            "claims_processed": claims,
            "open_disputes": all_disputes,
            "upcoming_appointments": upcoming_appointments,
            "refills_due": refills_due,
            "care_gaps": care_gaps,
            "benefits_found": benefits_found,
            "overdue_bills": overdue_bills
        };

        financial_summary = {
            "period": f"{ps[:10]} to {pe[:10]}",
            "claims_total": sum(c["amount"] for c in claims),
            "disputed_total": sum(d["amount"] for d in all_disputes),
            "potential_benefits_monthly": sum(b["monthly_savings"] for b in benefits_found)
        };

        all_alerts = scam_alerts + [
            {"type": g["type"], "urgency": g["urgency"]}
            for g in care_gaps
            if g["urgency"] in ["HIGH", "CRITICAL"]
        ];

        # --- Generate digest via LLM ---
        content = generate_weekly_digest(
            activity_summary=activity,
            pending_actions=pending_actions,
            financial_summary=financial_summary,
            alerts=all_alerts
        );

        digest = Digest(
            digest_id=str(uuid4()),
            period_start=ps,
            period_end=pe,
            generated_at=datetime.utcnow().isoformat(),
            executive_summary=content.get("executive_summary", ""),
            new_documents=str(content.get("new_documents", "")),
            claims_activity=str(content.get("claims_activity", "")),
            disputes_update=str(content.get("disputes_update", "")),
            upcoming_deadlines=str(content.get("upcoming_deadlines", "")),
            financial_summary=str(content.get("financial_summary", "")),
            alerts_section=str(content.get("alerts", "")),
            action_items=content.get("action_items", []),
            full_content=str(content),
            delivery_status="PENDING"
        );
        here ++> digest;
        print(f"[DigestGenerator] Generated digest {digest.digest_id} for {here.name}");
        print(f"  Appointments: {len(upcoming_appointments)} | Refills due: {len(refills_due)} | Care gaps: {len(care_gaps)} | Benefits: {len(benefits_found)}");

        report {
            "digest_id": digest.digest_id,
            "patient": here.name,
            "upcoming_appointments": len(upcoming_appointments),
            "refills_due": len(refills_due),
            "care_gaps": len(care_gaps),
            "benefits_found": len(benefits_found),
            "open_disputes": len(all_disputes)
        };
    }
}
