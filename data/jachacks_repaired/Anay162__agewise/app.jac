"""AgeWise — Autonomous Bureaucracy Agent for Aging Parents.

Entry point for the Jac runtime. Starts the server and mounts all modules.

Usage:
  jac run app.jac               # Run with demo mode
  jac start app.jac             # Start REST API server

Environment:
  Copy .env.example to .env and fill in API keys before running.
"""

import from config.settings { OPENROUTER_API_KEY, APP_ENV, DEBUG }
import from graph.nodes.patient { Patient }
import from graph.nodes.adult_child { AdultChild }
import from graph.nodes.document { Document }
import from graph.nodes.claim { Claim }
import from graph.nodes.line_item { LineItem }
import from graph.nodes.eob { EOB }
import from graph.nodes.dispute { Dispute }
import from graph.nodes.appeal { Appeal }
import from graph.nodes.provider { Provider }
import from graph.nodes.insurer { Insurer }
import from graph.nodes.policy { Policy }
import from graph.nodes.phone_call { PhoneCall }
import from graph.nodes.notification { Notification }
import from graph.nodes.financial_account { FinancialAccount }
import from graph.nodes.transaction { Transaction }

import from uuid { uuid4 }


# ─── Demo walker ───────────────────────────────────────────────────────────────

"""Creates a demo patient graph for testing and demonstration."""
walker DemoSetup {
    can setup with Patient entry {
        print(f"\n  Setting up demo data on patient: {here.name}");

        # Add demo insurer
        insurer = Insurer(
            payer_id="00001",
            name="Medicare (Part B)",
            plan_types=["MEDICARE_PART_B"],
            claims_phone="1-800-633-4227",
            appeals_fax="1-800-333-0235"
        );
        root ++> insurer;

        # Add demo provider
        provider = Provider(
            npi="1234567890",
            name="Springfield Medical Group",
            specialty="Internal Medicine",
            address="456 Medical Blvd",
            city="Springfield",
            state="IL",
            zip_code="62701"
        );
        root ++> provider;

        # Create a demo claim
        claim = Claim(
            claim_number="CLM-2024-001",
            claim_type="CMS1500",
            service_date_start="2024-11-15",
            service_date_end="2024-11-15",
            total_charges=350.00,
            amount_paid=90.00,
            patient_responsibility=32.50,
            status="PAID",
            created_at="2024-11-15T00:00:00"
        );
        here ++> claim;
        claim ++> provider;
        claim ++> insurer;

        # Line items
        line1 = LineItem(
            line_number=1,
            cpt_code="99213",
            units=1.0,
            charge_amount=250.00,
            service_date="2024-11-15",
            place_of_service_code="11",
            description="Office visit, established patient, level 3",
            icd_diagnosis_pointers=["A"]
        );
        line2 = LineItem(
            line_number=2,
            cpt_code="93000",
            units=1.0,
            charge_amount=100.00,
            service_date="2024-11-15",
            description="Electrocardiogram",
            icd_diagnosis_pointers=["A"]
        );
        claim ++> line1;
        claim ++> line2;

        # EOB
        eob = EOB(
            eob_id=str(uuid4()),
            eob_type="MSN_PART_B",
            payer_name="Medicare Part B",
            adjudication_date="2024-11-30",
            total_billed=350.00,
            medicare_approved=175.00,
            medicare_paid=140.00,
            patient_responsibility=35.00,
            appeal_deadline="2025-03-31",
            created_at="2024-11-15T00:00:00"
        );
        claim ++> eob;

        print(f"  ✓ Demo claim: {claim.claim_number} (${claim.total_charges:.2f})");
        print(
            f"  ✓ Line items: {line1.cpt_code} (${line1.charge_amount:.2f}), {line2.cpt_code} (${line2.charge_amount:.2f})"
        );

        report {
            "status": "demo_setup_complete",
            "claim_number": claim.claim_number,
            "line_items": 2
        };
    }
}


"""Returns a summary of a patient's current state."""
walker PatientSummary {
    can summarize with Patient entry {
        claims = [
            c
            for c in [here-->]
            if isinstance(c, Claim)
        ];
        open_disputes_count = 0;
        total_disputed = 0.0;

        for claim in claims {
            for item in [claim-->] {
                if isinstance(item, LineItem) {
                    for d in [item-->] {
                        if isinstance(d, Dispute)
                            and d.status in ["OPEN", "IN_PROGRESS", "APPEALED"] {
                            open_disputes_count += 1;
                            total_disputed += d.amount_disputed;
                        }
                    }
                }
            }
        }

        summary = {
            "patient": here.name,
            "medicare_id": here.medicare_id,
            "claims": len(claims),
            "total_billed": sum(c.total_charges for c in claims),
            "total_paid": sum(c.amount_paid for c in claims),
            "open_disputes": open_disputes_count,
            "total_disputed": total_disputed
        };

        print(f"\n  Patient: {here.name} (Medicare: {here.medicare_id})");
        print(
            f"  Claims: {summary['claims']} | Billed: ${summary[
                'total_billed'
            ]:.2f} | Paid: ${summary['total_paid']:.2f}"
        );
        print(
            f"  Open Disputes: {summary['open_disputes']} | At stake: ${summary[
                'total_disputed'
            ]:.2f}"
        );

        report summary;
    }
}


# ─── Client-side root app ─────────────────────────────────────────────────────

import from components.layout { Layout }
import from pages.dashboard { Dashboard }
import from pages.appointments { Appointments }
import from pages.medications { Medications }
import from pages.documents { Documents }
import from pages.claims { Claims }
import from pages.finances { Finances }
import from pages.settings { Settings }

import from "react-router-dom" { BrowserRouter, Routes, Route }

def:pub app() -> JsxElement {
    return
        <BrowserRouter>
            <Layout>
                <Routes>
                    <Route path="/" element={<Dashboard/>}/>
                    <Route path="/appointments" element={<Appointments/>}/>
                    <Route path="/medications" element={<Medications/>}/>
                    <Route path="/documents" element={<Documents/>}/>
                    <Route path="/claims" element={<Claims/>}/>
                    <Route path="/finances" element={<Finances/>}/>
                    <Route path="/settings" element={<Settings/>}/>
                </Routes>
            </Layout>
        </BrowserRouter>;
}


# ─── Main entry point ──────────────────────────────────────────────────────────

with entry {
    print("╔══════════════════════════════════════════╗");
    print("║  AgeWise — Medicare Billing Agent v0.1   ║");
    print("╚══════════════════════════════════════════╝");
    print(f"  Environment : {APP_ENV}");
    print(
        f"  LLM         : {'Configured ✓'
            if OPENROUTER_API_KEY
            else 'MISSING — set OPENROUTER_API_KEY in .env'}"
    );
    print("");

    # Create demo patient graph in development mode
    if APP_ENV == "development" {
        print("[demo] Creating demo patient graph...");

        patient = Patient(
            name="Margaret Johnson",
            dob="1948-03-15",
            medicare_id="1EG4-TE5-MK72",
            address="123 Oak Street",
            city="Springfield",
            state="IL",
            zip_code="62701",
            phone="555-867-5309",
            email="margaret@example.com",
            created_at="2024-11-15T00:00:00"
        );
        root ++> patient;
        print(f"  ✓ Patient: {patient.name}");

        child = AdultChild(
            name="Robert Johnson",
            email="robert.johnson@example.com",
            phone="555-234-5678",
            relationship="child",
            authority_level=2,
            hipaa_auth_on_file=True,
            notify_email=True,
            created_at="2024-11-15T00:00:00"
        );
        root ++> child;
        child ++> patient;
        print(f"  ✓ Caregiver: {child.name}");

        # Run demo setup walker on patient
        patient spawn DemoSetup();

        # Print patient summary
        patient spawn PatientSummary();

        print("\n[demo] Ready. To run pipelines:");
        print("  patient spawn DisputePipeline(patient_state='IL')");
        print("  patient spawn DocumentPipeline(source='upload', ...)");
        print("  patient spawn WeeklyDigestPipeline()");
    }
}


# ─── Frontend app component ────────────────────────────────────────────────────

def:pub app -> JsxElement {
    has currentPage: str = "dashboard",
        patientName: str = "Margaret Johnson";

    def navigate(pg: str) {
        currentPage = pg;
    }

    navItems = [
        {"id": "dashboard", "label": "Dashboard"},
        {"id": "bills", "label": "Bills & Claims"},
        {"id": "disputes", "label": "Disputes"},
        {"id": "documents", "label": "Documents"},
        {"id": "appointments", "label": "Appointments"},
        {"id": "medications", "label": "Medications"},
        {"id": "benefits", "label": "Benefits"},
        {"id": "subscriptions", "label": "Subscriptions"},
        {"id": "legal", "label": "Legal & Estate"},
        {"id": "finances", "label": "Finances"}
    ];

    pageContent = {
        "dashboard": {
            "title": "Dashboard",
            "desc": "Patient overview — claims, disputes, and recent activity."
        },
        "bills": {
            "title": "Bills & Claims",
            "desc": "Medicare claims, EOBs, and bill reconciliation."
        },
        "disputes": {
            "title": "Disputes & Appeals",
            "desc": "Active billing disputes and appeal status."
        },
        "documents": {
            "title": "Documents",
            "desc": "Upload and review EOBs, MSNs, and bills."
        },
        "appointments": {
            "title": "Appointments",
            "desc": "Upcoming appointments and care gap alerts."
        },
        "medications": {
            "title": "Medications",
            "desc": "Active medications, refill status, and interactions."
        },
        "benefits": {
            "title": "Benefits Check",
            "desc": "Government benefit programs you may qualify for."
        },
        "subscriptions": {
            "title": "Subscriptions",
            "desc": "Recurring charges and cancellation opportunities."
        },
        "legal": {
            "title": "Legal & Estate",
            "desc": "POA, will, HIPAA auth, and beneficiary status."
        },
        "finances": {
            "title": "Finances",
            "desc": "Linked accounts and transaction history."
        }
    };

    page = pageContent.get(currentPage, pageContent["dashboard"]);
    pageTitle = page["title"];
    pageDesc = page["desc"];

    return
        <div
            style={{
                "display": "flex",
                "minHeight": "100vh",
                "fontFamily": "-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif",
                "background": "#f8fafc"
            }}
        >
            <nav
                style={{
                    "width": "220px",
                    "background": "#0f172a",
                    "color": "#e2e8f0",
                    "display": "flex",
                    "flexDirection": "column",
                    "flexShrink": "0"
                }}
            >
                <div style={{"padding": "24px 20px 20px"}}>
                    <div
                        style={{
                            "fontSize": "20px",
                            "fontWeight": "700",
                            "color": "#38bdf8"
                        }}
                    >
                        AgeWise
                    </div>
                    <div
                        style={{
                            "fontSize": "11px",
                            "color": "#64748b",
                            "marginTop": "2px"
                        }}
                    >
                        Medicare Advocate
                    </div>
                </div>
                <div
                    style={{
                        "padding": "0 12px 16px",
                        "borderBottom": "1px solid #1e293b"
                    }}
                >
                    <div
                        style={{
                            "fontSize": "11px",
                            "color": "#475569",
                            "textTransform": "uppercase",
                            "letterSpacing": ".06em",
                            "marginBottom": "4px"
                        }}
                    >
                        Patient
                    </div>
                    <div style={{"fontSize": "14px", "fontWeight": "500"}}>
                        {patientName}
                    </div>
                </div>
                <ul
                    style={{
                        "listStyle": "none",
                        "margin": "8px 0",
                        "padding": "0",
                        "flex": "1"
                    }}
                >
                    {[
                        <li
                            key={item["id"]}
                            onClick={lambda { navigate(item["id"]); }}
                            style={{
                                "padding": "9px 20px",
                                "cursor": "pointer",
                                "fontSize": "13px",
                                "borderRadius": "6px",
                                "margin": "1px 8px",
                                "background": (
                                    "#1e3a5f"
                                        if item["id"] == currentPage
                                        else "transparent"
                                ),
                                "color": (
                                    "#38bdf8"
                                        if item["id"] == currentPage
                                        else "#94a3b8"
                                ),
                                "fontWeight": (
                                    "600" if item["id"] == currentPage else "400"
                                )
                            }}
                        >
                            {item["label"]}
                        </li> for item in navItems
                    ]}
                </ul>
            </nav>
            <main style={{"flex": "1", "padding": "36px 40px", "overflow": "auto"}}>
                <div style={{"maxWidth": "900px"}}>
                    <h1
                        style={{
                            "margin": "0 0 6px",
                            "fontSize": "26px",
                            "fontWeight": "700",
                            "color": "#0f172a"
                        }}
                    >
                        {pageTitle}
                    </h1>
                    <p
                        style={{
                            "margin": "0 0 32px",
                            "fontSize": "14px",
                            "color": "#64748b"
                        }}
                    >
                        {pageDesc}
                    </p>
                    <div
                        style={{
                            "background": "white",
                            "borderRadius": "10px",
                            "padding": "40px",
                            "boxShadow": "0 1px 4px rgba(0,0,0,.08)",
                            "border": "1px solid #e2e8f0"
                        }}
                    >
                        <p
                            style={{
                                "color": "#94a3b8",
                                "fontSize": "14px",
                                "textAlign": "center",
                                "margin": "0"
                            }}
                        >
                            Content for{" "}
                            <strong>{pageTitle}</strong>{" "}
                            loads here.
                        </p>
                    </div>
                </div>
            </main>
        </div>;
}
