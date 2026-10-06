"""Mock data for demo / when Jac server is not running.
Set USE_MOCK = False to call live backend walkers instead.
"""

glob USE_MOCK: bool = True;

glob MOCK_PATIENT: dict = {
         "name": "Margaret Johnson",
         "dob": "1948-03-15",
         "medicare_id": "1EG4-TE5-MK72",
         "state": "IL",
         "city": "Springfield"
     };

glob MOCK_DIGEST: dict = {
         "executive_summary": "This week was relatively calm for Margaret. One new Medicare statement arrived, a billing error was detected on her November cardiology visit, and two prescriptions are coming up for refill. Her annual PCP visit is now 14 months overdue — scheduling that should be the top priority this week.",
         "action_items": [
             "Schedule Margaret's overdue annual PCP visit — call Springfield Medical Group at (217) 555-0101",
             "Refill Metformin 500mg at Walgreens before it runs out in 5 days",
             "Review and approve dispute for cardiology overbilling ($87.50)",
             "Apply for Medicare Extra Help — estimated $340/month savings",
             "Confirm dental appointment on April 12th"
         ],
         "new_documents": "1 Medicare Summary Notice (Part B) received. Processed and summarized.",
         "claims_activity": "2 claims processed this week totalling $1,240. 1 billing error flagged.",
         "disputes_update": "1 open dispute ($87.50 overbilling on 99214 office visit). Appeal letter ready to send.",
         "upcoming_deadlines": "Appeal deadline for CLM-2024-001: May 15, 2026",
         "financial_summary": "Medical spend this month: $312. Potential new benefits: $340/mo (Extra Help).",
         "alerts_section": ""
     };

glob MOCK_APPOINTMENTS: list = [
         {
             "appointment_id": "appt-001",
             "appointment_date": "2026-04-12",
             "appointment_time": "10:30",
             "provider_name": "Dr. Susan Chen",
             "specialty": "Dentist",
             "facility_name": "Springfield Dental Group",
             "facility_address": "789 Oak Avenue, Springfield, IL",
             "purpose": "Routine cleaning and exam",
             "status": "SCHEDULED",
             "reminder_sent": False
         },
         {
             "appointment_id": "appt-002",
             "appointment_date": "2026-04-18",
             "appointment_time": "14:00",
             "provider_name": "Dr. James Park",
             "specialty": "Cardiology",
             "facility_name": "Memorial Heart Center",
             "facility_address": "200 Medical Drive, Springfield, IL",
             "purpose": "Follow-up after stress test",
             "status": "SCHEDULED",
             "reminder_sent": False
         },
         {
             "appointment_id": "appt-003",
             "appointment_date": "2026-03-15",
             "appointment_time": "09:00",
             "provider_name": "Dr. Maria Santos",
             "specialty": "Internal Medicine",
             "facility_name": "Springfield Medical Group",
             "facility_address": "456 Medical Blvd, Springfield, IL",
             "purpose": "Annual wellness visit",
             "status": "COMPLETED",
             "reminder_sent": True
         }
     ];

glob MOCK_CARE_GAPS: list = [
         {
             "gap_id": "gap-001",
             "gap_type": "MISSED_PCP",
             "specialty_needed": "Primary Care Physician",
             "last_visit_date": "2025-02-01",
             "days_overdue": 61,
             "urgency": "HIGH",
             "resolved": False
         },
         {
             "gap_id": "gap-002",
             "gap_type": "MISSED_VISION",
             "specialty_needed": "Eye Doctor",
             "last_visit_date": "2023-11-15",
             "days_overdue": 180,
             "urgency": "MEDIUM",
             "resolved": False
         }
     ];

glob MOCK_MEDICATIONS: list = [
         {
             "medication_id": "med-001",
             "drug_name": "Metformin",
             "generic_name": "metformin",
             "strength": "500mg",
             "form": "TABLET",
             "therapeutic_class": "Biguanide (Diabetes)",
             "prescribing_provider": "Dr. Maria Santos",
             "pharmacy_name": "Walgreens",
             "last_filled": "2026-03-01",
             "days_supply": 30,
             "refills_remaining": 5,
             "next_fill_due": "2026-03-31",
             "days_until_refill": -4,
             "active": True,
             "known_interactions": []
         },
         {
             "medication_id": "med-002",
             "drug_name": "Lisinopril",
             "generic_name": "lisinopril",
             "strength": "10mg",
             "form": "TABLET",
             "therapeutic_class": "ACE Inhibitor (Blood Pressure)",
             "prescribing_provider": "Dr. James Park",
             "pharmacy_name": "Walgreens",
             "last_filled": "2026-03-10",
             "days_supply": 30,
             "refills_remaining": 3,
             "next_fill_due": "2026-04-09",
             "days_until_refill": 5,
             "active": True,
             "known_interactions": []
         },
         {
             "medication_id": "med-003",
             "drug_name": "Atorvastatin",
             "generic_name": "atorvastatin",
             "strength": "20mg",
             "form": "TABLET",
             "therapeutic_class": "Statin (Cholesterol)",
             "prescribing_provider": "Dr. Maria Santos",
             "pharmacy_name": "CVS",
             "last_filled": "2026-03-05",
             "days_supply": 90,
             "refills_remaining": 2,
             "next_fill_due": "2026-06-03",
             "days_until_refill": 60,
             "active": True,
             "known_interactions": []
         },
         {
             "medication_id": "med-004",
             "drug_name": "Warfarin",
             "generic_name": "warfarin",
             "strength": "5mg",
             "form": "TABLET",
             "therapeutic_class": "Anticoagulant (Blood Thinner)",
             "prescribing_provider": "Dr. James Park",
             "pharmacy_name": "Walgreens",
             "last_filled": "2026-03-20",
             "days_supply": 30,
             "refills_remaining": 6,
             "next_fill_due": "2026-04-19",
             "days_until_refill": 15,
             "active": True,
             "known_interactions": ["Atorvastatin"]
         }
     ];

glob MOCK_INTERACTIONS: list = [
         {
             "drug_a": "Warfarin",
             "drug_b": "Atorvastatin",
             "severity": "MODERATE",
             "clinical_effect": "Atorvastatin may increase the anticoagulant effect of warfarin, raising bleeding risk.",
             "recommendation": "Monitor INR closely when starting or adjusting atorvastatin. Notify prescriber."
         }
     ];

glob MOCK_DISPUTES: list = [
         {
             "dispute_id": "disp-001",
             "error_type": "FEE_SCHEDULE_EXCESS",
             "amount_disputed": 87.50,
             "severity": "MEDIUM",
             "status": "OPEN",
             "deadline": "2026-05-15",
             "claim_number": "CLM-2024-001",
             "cpt_code": "99214",
             "description": "Billed $285 for established patient office visit; Medicare allowable is $197.50.",
             "appeal_level": 1
         }
     ];

glob MOCK_BENEFITS: list = [
         {
             "eligibility_id": "ben-001",
             "program_name": "Medicare Extra Help (Low Income Subsidy)",
             "program_type": "EXTRA_HELP",
             "is_eligible": True,
             "confidence_score": 0.85,
             "eligibility_reason": "Income below 150% FPL. Assets within threshold.",
             "estimated_savings_monthly": 340,
             "application_url": "https://www.ssa.gov/medicare/part-d/costs/extra-help",
             "application_phone": "1-800-772-1213"
         },
         {
             "eligibility_id": "ben-002",
             "program_name": "SNAP Food Assistance",
             "program_type": "SNAP",
             "is_eligible": False,
             "confidence_score": 0.75,
             "eligibility_reason": "Estimated income slightly above 130% FPL threshold. Verify with actual SSA-1099.",
             "estimated_savings_monthly": 0,
             "application_url": "",
             "application_phone": ""
         },
         {
             "eligibility_id": "ben-003",
             "program_name": "LIHEAP Utility Assistance",
             "program_type": "LIHEAP",
             "is_eligible": True,
             "confidence_score": 0.80,
             "eligibility_reason": "Income below 150% FPL, Illinois resident.",
             "estimated_savings_monthly": 45,
             "application_url": "https://www2.illinois.gov/dceo/communityservices/liheap",
             "application_phone": "1-800-252-8643"
         }
     ];

glob MOCK_SUBSCRIPTIONS: list = [
         {
             "subscription_id": "sub-001",
             "service_name": "Netflix",
             "category": "STREAMING",
             "monthly_cost": 15.49,
             "classification": "wasteful",
             "cancel_recommendation": True,
             "is_used": False,
             "utility_score": 0.1,
             "status": "ACTIVE"
         },
         {
             "subscription_id": "sub-002",
             "service_name": "Walgreens Prescription Delivery",
             "category": "HEALTH",
             "monthly_cost": 4.99,
             "classification": "useful",
             "cancel_recommendation": False,
             "is_used": True,
             "utility_score": 0.9,
             "status": "ACTIVE"
         },
         {
             "subscription_id": "sub-003",
             "service_name": "AARP Membership",
             "category": "OTHER",
             "monthly_cost": 3.00,
             "classification": "useful",
             "cancel_recommendation": False,
             "is_used": True,
             "utility_score": 0.8,
             "status": "ACTIVE"
         },
         {
             "subscription_id": "sub-004",
             "service_name": "Tech Support Protection Plan",
             "category": "OTHER",
             "monthly_cost": 29.99,
             "classification": "suspicious",
             "cancel_recommendation": True,
             "is_used": False,
             "utility_score": 0.0,
             "status": "ACTIVE"
         }
     ];
