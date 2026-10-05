"""frontend.cl.jac — Jac-native React UI for the Insurance Appeal Agent.

This file IS the frontend. No HTML template, no hand-rolled fetch(), no
separate JS bundle: the `.cl.jac` extension marks this as Jac
client code that compiles straight into a React bundle. State, JSX,
event handlers, and `root spawn` walker calls all live in one file.

Loaded by `app.jac`, which is the actual `jac start` entry point.
"""

# Pull walker types into the client namespace so `root spawn ...` is
# typed. `sv` keeps these on the server side; the client only sees the
# RPC shape, not the walker bodies.
import from walkers { submit_claim, list_appeals }


def:pub app -> JsxElement {
    # Reactive state — Jac `has` is roughly React's useState.
    has patient: str = "Jordan A. Reyes",
        member: str = "BSH-44892-01",
        claim_num: str = "CLM-2026-0418-9921",
        dos: str = "2026-04-18",
        cpt: str = "95810",
        amount: str = "3847.00",
        plan: str = "BlueShield PPO Gold 2026",
        denial: str = "",
        policy: str = "",
        record: str = "",
        loading: bool = False,
        status_msg: str = "",
        status_kind: str = "",                # "ok" | "warn" | ""
        phase_idx: int = 0,
        subject: str = "",
        letter_body: str = "",
        citations: list = [],
        appeal_id: str = "",
        history: list = [];

    # Rotating "thinking" phases — surfaces that the orchestrator is
    # doing real agentic work (plan -> extract -> map -> contradict
    # -> draft) rather than presenting a single opaque spinner.
    phases = [
        "planning tool order…",
        "extracting policy clauses…",
        "mapping clinical facts to criteria…",
        "detecting contradictions…",
        "drafting appeal letter…"
    ];

    # Sample claim pre-fill — same content as samples/*.txt so the
    # demo is a one-click affair.
    def loadSample -> None {
        patient = "Jordan A. Reyes";
        member = "BSH-44892-01";
        claim_num = "CLM-2026-0418-9921";
        dos = "2026-04-18";
        cpt = "95810";
        amount = "3847.00";
        plan = "BlueShield PPO Gold 2026";
        denial = "BlueShield Health Plans — May 2, 2026\n\nClaim CLM-2026-0418-9921 for in-lab polysomnography (CPT 95810) is DENIED. Reason M-114: NOT MEDICALLY NECESSARY. Clinical documentation does not establish that home sleep apnea testing (HSAT) was attempted and failed prior to the in-lab study. Per our clinical policy, in-lab polysomnography is reserved for cases where HSAT is contraindicated or has been attempted and returned a non-diagnostic result.";
        policy = "BLUESHIELD PPO GOLD 2026 — Section 7.2\nMEDICAL NECESSITY CRITERIA FOR IN-LAB POLYSOMNOGRAPHY (CPT 95810)\n\nIn-lab polysomnography is considered medically necessary when ANY of the following are met:\n  (i)   Comorbid condition that renders HSAT unreliable, including\n        moderate-to-severe pulmonary disease, congestive heart\n        failure (NYHA Class III or IV), neuromuscular disease, or\n        chronic opioid use.\n  (ii)  HSAT has been attempted and returned a non-diagnostic result.\n  (iii) Clinical suspicion of a non-respiratory sleep disorder.\n  (iv)  Patient unable to operate HSAT equipment safely at home.\n\n7.3 Prior authorization is NOT required when ordered by a board-\ncertified sleep medicine physician, pulmonologist, or neurologist.";
        record = "Patient: Jordan A. Reyes\nNYHA Class III congestive heart failure (LVEF 28% Feb 2026).\nChronic daily opioid therapy (oxycodone ER 20mg BID) since 2023.\nWitnessed apneas, Epworth Sleepiness Scale 18/24.\nOrder date: 2026-04-10  |  Study performed: 2026-04-18";
        status_msg = "Sample claim loaded. Click Generate appeal.";
        status_kind = "ok";
    }

    async def refreshHistory -> None {
        try {
            result = root spawn list_appeals();
            rows = (
                result.reports[0]
                    if (result.reports and len(result.reports) > 0)
                    else []
            );
            history = rows;
        } except Exception {
            history = [];
        }
    }

    # Fire once on mount: load any previously persisted appeals.
    async can with entry {
        refreshHistory();
    }

    # Reactive phase rotator: every time `loading` flips on, kick off
    # a JS interval that bumps `phase_idx`. The callback self-clears
    # when loading drops, so no useEffect-cleanup return is needed.
    can with [loading] entry {
        if loading {
            handle = setInterval(
                lambda {
                    if not loading { clearInterval(handle); }
                    else { phase_idx = (phase_idx + 1) % 5; }
                },
                1800
            );
        }
    }

    async def submit -> None {
        if not denial.strip() or not policy.strip() {
            status_msg = "Paste a denial letter and policy first.";
            status_kind = "warn";
            return;
        }
        loading = True;
        status_msg = "Agent running — 30–60 seconds.";
        status_kind = "warn";
        subject = "";
        letter_body = "";
        citations = [];
        appeal_id = "";
        phase_idx = 0;
        try {
            # THIS is the whole point of `.cl.jac`: a typed walker
            # call from the React component, no fetch() in sight.
            result = root spawn submit_claim(
                patient_name=patient,
                member_id=member,
                claim_number=claim_num,
                date_of_service=dos,
                cpt_code=cpt,
                billed_amount=float(amount or "0"),
                plan_name=plan,
                denial_text=denial,
                policy_text=policy,
                clinical_record=record
            );
            # Walker `report` envelope:
            #   result.reports == [ [ {appeal_id, subject, letter, citations} ] ]
            reports = (
                result.reports[0]
                    if (result.reports and len(result.reports) > 0)
                    else []
            );
            payload = reports[0] if (reports and len(reports) > 0) else None;
            if payload {
                subject = payload["subject"] if "subject" in payload else "(no subject)";
                letter_body = payload["letter"] if "letter" in payload else "(empty letter)";
                citations = payload["citations"] if "citations" in payload else [];
                appeal_id = payload["appeal_id"] if "appeal_id" in payload else "";
                status_msg = "Done — appeal " + appeal_id + " saved.";
                status_kind = "ok";
            } else {
                status_msg = "Agent returned no payload.";
                status_kind = "warn";
            }
            refreshHistory();
        } except Exception as e {
            status_msg = "Error: " + str(e);
            status_kind = "warn";
        }
        loading = False;
    }

    # ---- Style tokens (kept inline so this file is self-contained)
    bg = "#0e1014";
    panel = "#161a22";
    panel2 = "#1d222d";
    border = "#262c3a";
    text_color = "#e7ecf3";
    muted = "#8a93a6";
    accent = "#4ea1ff";
    ok_color = "#4ad17a";
    warn_color = "#f2b95b";

    page_style = {
        "background": bg,
        "color": text_color,
        "minHeight": "100vh",
        "fontFamily": "-apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, sans-serif",
        "fontSize": "14px",
        "lineHeight": "1.5"
    };
    header_style = {
        "padding": "24px 32px 16px",
        "borderBottom": "1px solid " + border,
        "display": "flex",
        "justifyContent": "space-between",
        "alignItems": "flex-end"
    };
    grid_style = {
        "display": "grid",
        "gridTemplateColumns": "1fr 1fr 1.2fr",
        "gap": "1px",
        "background": border,
        "minHeight": "calc(100vh - 84px)"
    };
    pane_style = {
        "background": bg,
        "padding": "20px 22px",
        "overflowY": "auto"
    };
    h2_style = {
        "margin": "0 0 12px",
        "fontSize": "12px",
        "fontWeight": "600",
        "textTransform": "uppercase",
        "letterSpacing": "0.08em",
        "color": muted
    };
    label_style = {
        "display": "block",
        "fontSize": "12px",
        "color": muted,
        "marginBottom": "4px"
    };
    input_style = {
        "width": "100%",
        "background": panel,
        "color": text_color,
        "border": "1px solid " + border,
        "borderRadius": "6px",
        "padding": "8px 10px",
        "font": "inherit",
        "boxSizing": "border-box"
    };
    textarea_style = {
        "width": "100%",
        "background": panel,
        "color": text_color,
        "border": "1px solid " + border,
        "borderRadius": "6px",
        "padding": "8px 10px",
        "fontFamily": "ui-monospace, SFMono-Regular, monospace",
        "fontSize": "12px",
        "minHeight": "260px",
        "resize": "vertical",
        "boxSizing": "border-box"
    };
    record_textarea_style = {
        "width": "100%",
        "background": panel,
        "color": text_color,
        "border": "1px solid " + border,
        "borderRadius": "6px",
        "padding": "8px 10px",
        "fontFamily": "ui-monospace, SFMono-Regular, monospace",
        "fontSize": "12px",
        "minHeight": "140px",
        "resize": "vertical",
        "boxSizing": "border-box"
    };
    button_style = {
        "background": accent,
        "color": "white",
        "border": "none",
        "borderRadius": "6px",
        "padding": "10px 16px",
        "fontWeight": "600",
        "cursor": "pointer",
        "marginRight": "8px"
    };
    button_disabled_style = {
        "background": "#333",
        "color": "white",
        "border": "none",
        "borderRadius": "6px",
        "padding": "10px 16px",
        "fontWeight": "600",
        "cursor": "not-allowed",
        "marginRight": "8px"
    };
    ghost_button_style = {
        "background": "transparent",
        "color": text_color,
        "border": "1px solid " + border,
        "borderRadius": "6px",
        "padding": "10px 16px",
        "fontWeight": "600",
        "cursor": "pointer",
        "marginRight": "8px"
    };
    status_style = {
        "fontSize": "12px",
        "color": (
            ok_color if status_kind == "ok"
            else (warn_color if status_kind == "warn" else muted)
        ),
        "marginLeft": "4px"
    };
    subject_style = {
        "fontWeight": "600",
        "padding": "10px 14px",
        "background": panel2,
        "border": "1px solid " + border,
        "borderLeft": "3px solid " + accent,
        "borderRadius": "6px",
        "marginBottom": "12px"
    };
    letter_style = {
        "background": panel,
        "border": "1px solid " + border,
        "borderRadius": "6px",
        "padding": "16px",
        "whiteSpace": "pre-wrap",
        "fontFamily": "ui-monospace, SFMono-Regular, monospace",
        "fontSize": "13px",
        "lineHeight": "1.6"
    };
    citations_style = {
        "marginTop": "14px",
        "padding": "12px 14px",
        "background": panel,
        "border": "1px solid " + border,
        "borderRadius": "6px",
        "fontSize": "12px"
    };
    empty_style = {
        "color": muted,
        "padding": "40px 20px",
        "textAlign": "center"
    };
    spinner_style = {
        "padding": "14px 16px",
        "background": panel2,
        "border": "1px solid " + border,
        "borderRadius": "6px",
        "fontFamily": "ui-monospace, SFMono-Regular, monospace",
        "fontSize": "13px",
        "color": warn_color,
        "marginBottom": "12px"
    };
    history_item_style = {
        "padding": "8px 10px",
        "borderBottom": "1px solid " + border,
        "fontSize": "12px",
        "color": muted
    };
    meta_grid_style = {
        "display": "grid",
        "gridTemplateColumns": "1fr 1fr",
        "gap": "8px"
    };
    title_style = {
        "fontSize": "20px",
        "fontWeight": "600",
        "letterSpacing": "-0.01em"
    };
    subtitle_style = {
        "color": muted,
        "fontSize": "12px",
        "marginTop": "4px"
    };
    served_style = {"color": muted, "fontSize": "11px"};

    current_phase = phases[phase_idx % 5];

    return
        <div style={page_style}>
            <div style={header_style}>
                <div>
                    <div style={title_style}>Insurance Appeal Agent</div>
                    <div style={subtitle_style}>
                        Single-file full-stack Jac · walkers + by llm() + React, all in .jac
                    </div>
                </div>
                <div style={served_style}>
                    served by jac start app.jac
                </div>
            </div>

            <div style={grid_style}>
                <section style={pane_style}>
                    <h2 style={h2_style}>1 · Denial letter</h2>
                    <textarea
                        value={denial}
                        placeholder="Paste the full text of the insurer's denial letter…"
                        onChange={lambda (e: any) { denial = e.target.value; }}
                        style={textarea_style}
                    />
                    <div style={{"marginTop": "14px"}}>
                        <h2 style={h2_style}>Claim metadata</h2>
                        <div style={meta_grid_style}>
                            <div>
                                <label style={label_style}>Patient</label>
                                <input
                                    value={patient}
                                    onChange={lambda (e: any) { patient = e.target.value; }}
                                    style={input_style}
                                />
                            </div>
                            <div>
                                <label style={label_style}>Member ID</label>
                                <input
                                    value={member}
                                    onChange={lambda (e: any) { member = e.target.value; }}
                                    style={input_style}
                                />
                            </div>
                            <div>
                                <label style={label_style}>Claim #</label>
                                <input
                                    value={claim_num}
                                    onChange={lambda (e: any) { claim_num = e.target.value; }}
                                    style={input_style}
                                />
                            </div>
                            <div>
                                <label style={label_style}>Date of service</label>
                                <input
                                    value={dos}
                                    onChange={lambda (e: any) { dos = e.target.value; }}
                                    style={input_style}
                                />
                            </div>
                            <div>
                                <label style={label_style}>CPT</label>
                                <input
                                    value={cpt}
                                    onChange={lambda (e: any) { cpt = e.target.value; }}
                                    style={input_style}
                                />
                            </div>
                            <div>
                                <label style={label_style}>Billed (USD)</label>
                                <input
                                    value={amount}
                                    onChange={lambda (e: any) { amount = e.target.value; }}
                                    style={input_style}
                                />
                            </div>
                        </div>
                        <div style={{"marginTop": "8px"}}>
                            <label style={label_style}>Plan name</label>
                            <input
                                value={plan}
                                onChange={lambda (e: any) { plan = e.target.value; }}
                                style={input_style}
                            />
                        </div>
                    </div>
                </section>

                <section style={pane_style}>
                    <h2 style={h2_style}>2 · Policy excerpt</h2>
                    <textarea
                        value={policy}
                        placeholder="Paste the relevant policy section(s) the agent should read…"
                        onChange={lambda (e: any) { policy = e.target.value; }}
                        style={textarea_style}
                    />
                    <div style={{"marginTop": "14px"}}>
                        <h2 style={h2_style}>Clinical record (optional)</h2>
                        <textarea
                            value={record}
                            placeholder="Comorbidities, medications, prior testing, indication notes…"
                            onChange={lambda (e: any) { record = e.target.value; }}
                            style={record_textarea_style}
                        />
                    </div>
                    <div style={{"marginTop": "16px"}}>
                        <button
                            style={ghost_button_style}
                            onClick={lambda (_e: any) { loadSample(); }}
                        >
                            Load sample claim
                        </button>
                        <button
                            style={(button_disabled_style if loading else button_style)}
                            disabled={loading}
                            onClick={lambda (_e: any) { submit(); }}
                        >
                            {"Working…" if loading else "Generate appeal"}
                        </button>
                        <div style={status_style}>{status_msg}</div>
                    </div>
                </section>

                <section style={pane_style}>
                    <h2 style={h2_style}>3 · Generated appeal</h2>

                    {<div style={spinner_style}>
                            ◐ agent · {current_phase}
                        </div> if loading else None}

                    {<div>
                            <div style={subject_style}>{subject}</div>
                            <pre style={letter_style}>{letter_body}</pre>
                            <div style={citations_style}>
                                <strong>Citations</strong>
                                <ul style={{"margin": "6px 0 0", "paddingLeft": "20px", "color": muted}}>
                                    {if len(citations) > 0 {
                                        for (i, c) in enumerate(citations) {
                                            <li key={i}>{c}</li>
                                        }
                                    } else {
                                        <li key="none">(none returned)</li>
                                    }}
                                </ul>
                            </div>
                            {<div style={{"marginTop": "10px", "fontSize": "11px", "color": muted}}>
                                    Persisted on graph as {appeal_id}
                                </div> if appeal_id else None}
                        </div> if subject else <div style={empty_style}>
                            {"Agent is thinking — output will appear here."
                                    if loading
                                    else "Paste a denial + policy on the left, then click Generate appeal."}
                        </div>}

                    {<div style={{"marginTop": "24px"}}>
                            <h2 style={h2_style}>Persisted appeals on the graph</h2>
                            <div
                                style={{
                                    "background": panel,
                                    "border": "1px solid " + border,
                                    "borderRadius": "6px"
                                }}
                            >
                                {for (i, h) in enumerate(history) {
                                    <div key={i} style={history_item_style}>
                                        <div style={{"color": text_color, "fontSize": "12px"}}>
                                            {h["subject"] if "subject" in h else "(untitled)"}
                                        </div>
                                        <div>
                                            {h["appeal_id"] if "appeal_id" in h else ""} · claim {h["claim_id"] if "claim_id" in h else ""}
                                        </div>
                                    </div>
                                }}
                            </div>
                        </div> if len(history) > 0 else None}
                </section>
            </div>
        </div>;
}
