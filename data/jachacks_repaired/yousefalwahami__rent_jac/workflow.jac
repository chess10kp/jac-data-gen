import from shared { IncidentRecord, panel_classes }

def:pub AiFlowDetailView(props: dict) -> JsxElement {
    incident = props["incident"];
    on_back = props["on_back"];

    has selected_node: any = None;

    # Derive real status from actual incident data
    has_message   = incident.message and len(incident.message) > 0;
    has_urgency   = incident.urgency and incident.urgency != "" and incident.urgency != "None";
    has_unit      = incident.unit and incident.unit != "?" and incident.unit != "" and incident.unit != "None";
    has_category  = incident.category and incident.category != "" and incident.category != "None";
    has_vendor    = incident.assignee and incident.assignee != "" and incident.assignee != "None";
    triage_ran    = has_urgency or has_unit or has_category;
    is_resolved   = incident.status == "Resolved";
    is_approved   = incident.status == "Approved";
    is_rejected   = incident.status == "Rejected";
    is_pending    = has_vendor and not is_resolved and not is_approved and not is_rejected;

    console.log("[workflow] incident:", incident);
    console.log("[workflow] has_message:", has_message, "triage_ran:", triage_ran, "has_vendor:", has_vendor, "is_resolved:", is_resolved);
    console.log("[workflow] timings:", incident.timings);

    node_timings = {
        "intake":          incident.timings["classify_ms"] if (incident.timings and "classify_ms" in incident.timings) else None,
        "triage_urgency":  incident.timings["urgency_ms"]  if (incident.timings and "urgency_ms" in incident.timings)  else None,
        "triage_entity":   incident.timings["entity_ms"]   if (incident.timings and "entity_ms" in incident.timings)   else None,
        "triage_class":    incident.timings["classify_ms"] if (incident.timings and "classify_ms" in incident.timings) else None,
        "context_vendor":  incident.timings["vendor_ms"]   if (incident.timings and "vendor_ms" in incident.timings)   else None,
        "risk_assess":     incident.timings["risk_ms"]     if (incident.timings and "risk_ms" in incident.timings)     else None,
        "msg_tenant":      incident.timings["comms_ms"]    if (incident.timings and "comms_ms" in incident.timings)    else None,
        "msg_owner":       incident.timings["comms_ms"]    if (incident.timings and "comms_ms" in incident.timings)    else None,
        "context_history": 2,
        "root":            0,
        "gate_approval":   None,
        "action_dispatch": None
    };

    nodes: any = [
        {"id": "root",            "label": "Incident Origin",  "x": 50,   "y": 300, "status": 2 if has_message else 0,                       "desc": "Inbound SMS message received",          "output": incident.message },
        {"id": "intake",          "label": "Message Intake",   "x": 340,  "y": 300, "status": 2 if triage_ran else (1 if has_message else 0), "desc": "Parses raw message and triggers triage", "output": "Parsed" if triage_ran else "Waiting" },
        {"id": "triage_urgency",  "label": "Urgency",          "x": 630,  "y": 150, "status": 2 if (has_urgency or has_vendor) else (1 if triage_ran else 0),  "desc": "Evaluates situational severity",         "output": incident.urgency if has_urgency else ("Done" if has_vendor else ("Analyzing..." if triage_ran else "—")) },
        {"id": "triage_entity",   "label": "Entity Match",     "x": 630,  "y": 300, "status": 2 if (has_unit or has_vendor) else (1 if triage_ran else 0),     "desc": "Identifies tenant and property",         "output": incident.unit if has_unit else ("Done" if has_vendor else ("Identifying..." if triage_ran else "—")) },
        {"id": "triage_class",    "label": "Classification",   "x": 630,  "y": 450, "status": 2 if (has_category or has_vendor) else (1 if triage_ran else 0), "desc": "Categorizes maintenance issue",          "output": incident.category if has_category else ("Done" if has_vendor else ("Classifying..." if triage_ran else "—")) },
        {"id": "context_history", "label": "Repair History",   "x": 920,  "y": 250, "status": 2 if triage_ran else 0,                         "desc": "Fetches previous tickets",               "output": "Checked" if triage_ran else "—" },
        {"id": "context_vendor",  "label": "Vendor Match",     "x": 920,  "y": 400, "status": 2 if has_vendor else (1 if triage_ran else 0),   "desc": "Finds suitable contractors",             "output": incident.assignee if has_vendor else "Searching..." },
        {"id": "risk_assess",     "label": "Risk Analyst",     "x": 1210, "y": 300, "status": 2 if has_vendor else 0,                         "desc": "Assesses liability and cost risks",      "output": "Low Risk" if has_vendor else "—" },
        {"id": "msg_tenant",      "label": "Tenant Reply",     "x": 1500, "y": 150, "status": 2 if has_vendor else 0,                         "desc": "Drafts acknowledgment SMS",              "output": "Draft Ready" if has_vendor else "—" },
        {"id": "msg_owner",       "label": "Owner Alert",      "x": 1500, "y": 300, "status": 2 if has_vendor else 0,                         "desc": "Drafts approval request",                "output": "Draft Ready" if has_vendor else "—" },
        {"id": "gate_approval",   "label": "Approval Gate",    "x": 1500, "y": 450, "status": 2 if (is_resolved or is_approved) else (4 if is_rejected else (3 if is_pending else 0)),  "desc": "Human in the loop checkpoint",          "output": "Approved" if (is_resolved or is_approved) else ("Rejected" if is_rejected else ("Pending" if is_pending else "—")) },
        {"id": "action_dispatch", "label": "Dispatch",         "x": 1790, "y": 450, "status": 2 if (is_resolved or is_approved) else (4 if is_rejected else 0),                    "desc": "Dispatches vendor",                      "output": "YES — Dispatched" if (is_resolved or is_approved) else ("NO — Rejected" if is_rejected else "—") }
    ];

    edges: any = [
        {"from": "root", "to": "intake"},
        {"from": "intake", "to": "triage_urgency"},
        {"from": "intake", "to": "triage_entity"},
        {"from": "intake", "to": "triage_class"},
        {"from": "triage_entity", "to": "context_history"},
        {"from": "triage_class", "to": "context_vendor"},
        {"from": "context_history", "to": "risk_assess"},
        {"from": "context_vendor", "to": "risk_assess"},
        {"from": "risk_assess", "to": "msg_tenant"},
        {"from": "risk_assess", "to": "msg_owner"},
        {"from": "msg_owner", "to": "gate_approval"},
        {"from": "gate_approval", "to": "action_dispatch"}
    ];

    def get_node(id: str) -> any {
        for n in nodes { if n["id"] == id { return n; } }
        return None;
    }

    def status_classes(s: int) -> str {
        if s == 0 { return "bg-white/60 border-slate-200/60 text-slate-400 opacity-60"; }
        if s == 1 { return "bg-white border-indigo-400 ring-4 ring-indigo-50 shadow-[0_8px_30px_rgba(99,102,241,0.15)] scale-105 z-20"; }
        if s == 2 { return "bg-white border-emerald-200 shadow-sm z-10 hover:shadow-md"; }
        if s == 3 { return "bg-white border-amber-300 shadow-[0_4px_20px_rgba(245,158,11,0.1)] z-10"; }
        if s == 4 { return "bg-white border-red-300 shadow-[0_4px_20px_rgba(239,68,68,0.1)] z-10"; }
        return "";
    }

    return (
        <div className="flex w-full h-full flex-col bg-slate-50 font-sans text-slate-800 relative overflow-hidden rounded-xl border border-slate-200 shadow-2xl">
            <div className="flex items-center justify-between p-6 border-b border-slate-200 bg-white/80 backdrop-blur z-30 shadow-sm">
                <div className="flex items-center gap-3">
                    <span className="text-xs font-mono font-bold text-slate-500 uppercase tracking-widest">Walker Execution Graph</span>
                    <span className={"px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider " + ("bg-emerald-100 text-emerald-700" if (is_resolved or is_approved) else ("bg-red-100 text-red-700" if is_rejected else ("bg-amber-100 text-amber-700" if is_pending else "bg-slate-100 text-slate-500")))}>
                        {incident.status if incident.status else "Processing"}
                    </span>
                </div>
            </div>

            <div className="flex-1 relative w-full h-full overflow-auto bg-slate-50 custom-scrollbar">
                <div className="absolute inset-0 z-0 opacity-40" style={{ backgroundImage: "radial-gradient(#94a3b8 1.5px, transparent 1.5px)", backgroundSize: "32px 32px" }}></div>
                <div className="absolute inset-0 z-0 opacity-20 bg-gradient-to-br from-indigo-50 to-emerald-50"></div>

                <div className="absolute min-w-[2100px] min-h-[800px] w-full h-full p-10 z-10 flex items-center">

                    <svg className="absolute top-0 left-0 w-full h-full pointer-events-none z-0">
                        {edges.map(lambda (e: dict) -> JsxElement {
                            n1 = get_node(e["from"]);
                            n2 = get_node(e["to"]);
                            active  = n1["status"] >= 1 and n2["status"] >= 1;
                            flowing = n1["status"] >= 1 and n2["status"] == 1;

                            p_x1  = str(n1["x"] + 240);
                            p_y1  = str(n1["y"] + 55);
                            p_x2  = str(n2["x"]);
                            p_y2  = str(n2["y"] + 55);
                            cp1_x = str(n1["x"] + 290);
                            cp2_x = str(n2["x"] - 50);
                            d_path = "M " + p_x1 + " " + p_y1 + " C " + cp1_x + " " + p_y1 + ", " + cp2_x + " " + p_y2 + ", " + p_x2 + " " + p_y2;

                            rejected_edge = (n1["status"] == 4 or n2["status"] == 4) and active;
                            stroke_color = "#cbd5e1";
                            if active { stroke_color = "#ef4444" if rejected_edge else ("#6366f1" if flowing else "#10b981"); }
                            stroke_w  = "2.5" if active else "2";
                            class_n   = "transition-all duration-700 opacity-100" if active else "transition-all duration-700 opacity-30";
                            dash_a    = "6 6" if flowing else "none";

                            return (
                                <g key={e["from"] + "-" + e["to"]}>
                                    <path d={d_path} fill="none" stroke={stroke_color} strokeWidth={stroke_w} className={class_n} strokeDasharray={dash_a} />
                                </g>
                            );
                        })}
                    </svg>

                    {nodes.map(lambda (n: dict) -> JsxElement {
                        trunc_output = str(n["output"]);
                        if len(trunc_output) > 28 { trunc_output = trunc_output[0:25] + "..."; }

                        node_classes   = "absolute w-[240px] h-[110px] p-4 rounded-2xl border flex flex-col justify-between cursor-pointer transition-all duration-500 backdrop-blur-md hover:ring-2 hover:ring-indigo-200 " + status_classes(n["status"]) + (" translate-y-8 opacity-0 scale-95" if n["status"] == 0 else " translate-y-0 opacity-100 scale-100");
                        label_classes  = "text-xs font-extrabold uppercase tracking-wider " + ("text-slate-800" if n["status"] >= 1 else "text-slate-500");
                        bar_classes    = "h-[3.5px] w-full rounded-full overflow-hidden mt-3 shadow-inner " + ("bg-slate-100" if n["status"] == 0 else ("bg-indigo-100" if n["status"] == 1 else ("bg-emerald-100" if n["status"] == 2 else ("bg-red-100" if n["status"] == 4 else "bg-amber-100"))));
                        output_classes = "absolute -bottom-9 rounded-full left-1/2 -translate-x-1/2 whitespace-nowrap px-3.5 py-1.5 shadow-lg border text-[11px] font-bold transition-all duration-500 z-30 " + ("bg-emerald-50 border-emerald-200 text-emerald-700 opacity-100 translate-y-0 scale-100" if n["status"] == 2 else ("bg-red-50 border-red-200 text-red-700 opacity-100 translate-y-0 scale-100" if n["status"] == 4 else ("bg-amber-50 border-amber-200 text-amber-700 opacity-100 translate-y-0 scale-100" if n["status"] == 3 else ("bg-indigo-50 border-indigo-200 text-indigo-600 opacity-100 translate-y-0 scale-100" if n["status"] == 1 else "opacity-0 -translate-y-6 scale-75 pointer-events-none"))));

                        return (
                            <div key={n["id"]} onClick={lambda () -> None { selected_node = n; console.log("[workflow] selected node:", n); }} className={node_classes} style={{ left: str(n["x"]) + "px", top: str(n["y"]) + "px" }}>
                                {n["status"] == 1 and <div className="absolute -inset-1.5 bg-indigo-500/10 rounded-3xl blur-xl -z-10 animate-pulse"></div>}
                                <div>
                                    <div className="flex items-center justify-between">
                                        <h4 className={label_classes}>{n["label"]}</h4>
                                        <div className="flex gap-1.5 shrink-0 ml-2 items-center">
                                            {node_timings[n["id"]] and n["status"] == 2 and <span className="text-[9px] font-mono font-bold text-emerald-600 bg-emerald-50 border border-emerald-100 px-1.5 py-0.5 rounded-full">{str(node_timings[n["id"]]) + "ms"}</span>}
                                            {n["status"] == 1 and <span className="w-2.5 h-2.5 rounded-full bg-indigo-500 animate-ping"></span>}
                                            {n["status"] == 2 and not node_timings[n["id"]] and <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 shadow-[0_0_8px_#34d399]"></span>}
                                            {n["status"] == 3 and <span className="w-2.5 h-2.5 rounded-full bg-amber-500 animate-pulse shadow-[0_0_8px_#fbbf24]"></span>}
                                            {n["status"] == 4 and <span className="w-2.5 h-2.5 rounded-full bg-red-500 shadow-[0_0_8px_#ef4444]"></span>}
                                        </div>
                                    </div>
                                    <p className={"text-[10.5px] leading-snug mt-1.5 font-medium line-clamp-2 " + ("text-slate-600" if n["status"] >= 1 else "text-slate-400")}>{n["desc"]}</p>
                                </div>
                                <div className={bar_classes}>
                                    {n["status"] == 1 and <div className="h-full w-1/3 bg-indigo-500 rounded-full animate-[slide_1.5s_ease-in-out_infinite]"></div>}
                                    {n["status"] == 2 and <div className="h-full w-full bg-emerald-500 rounded-full"></div>}
                                    {n["status"] == 3 and <div className="h-full w-full bg-amber-500 rounded-full"></div>}
                                    {n["status"] == 4 and <div className="h-full w-full bg-red-500 rounded-full"></div>}
                                </div>
                                <div className={output_classes}>
                                    <div className="flex items-center gap-1.5">
                                        {n["status"] == 2 and <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M5 13l4 4L19 7" /></svg>}
                                        {n["status"] == 3 and <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>}
                                        {n["status"] == 4 and <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M6 18L18 6M6 6l12 12" /></svg>}
                                        {n["status"] == 1 and <span className="w-2 h-2 rounded-full bg-indigo-500 animate-pulse inline-block shrink-0"></span>}
                                        {trunc_output}
                                    </div>
                                </div>
                            </div>
                        );
                    })}
                </div>
            </div>

            {selected_node and (
                <div className="absolute top-0 right-0 w-[420px] h-full bg-white/95 backdrop-blur-3xl border-l border-slate-200 shadow-[0_0_40px_rgba(0,0,0,0.1)] p-8 z-40 transform transition-transform duration-500 animate-[slideLeft_0.4s_ease-out]">
                    <div className="flex items-center justify-between mb-8 pb-5 border-b border-slate-100">
                        <div className="flex items-center gap-3">
                            <div className="w-10 h-10 rounded-xl bg-indigo-50 border border-indigo-100 flex items-center justify-center text-indigo-500 shadow-sm">
                                <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M13 10V3L4 14h7v7l9-11h-7z" /></svg>
                            </div>
                            <h2 className="text-xs font-extrabold tracking-widest uppercase text-slate-500">Walker Inspector</h2>
                        </div>
                        <button onClick={lambda () -> None { selected_node = None; }} className="text-slate-400 hover:text-slate-900 bg-slate-50 p-2 rounded-full hover:bg-slate-100 border border-slate-200/50">
                            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12" /></svg>
                        </button>
                    </div>
                    <div className="space-y-6">
                        <div>
                            <h3 className="text-2xl font-extrabold text-slate-900 tracking-tight mb-2">{selected_node["label"]}</h3>
                            <p className="text-[11px] font-mono font-bold text-slate-500 border border-slate-200 bg-slate-50 px-2 py-0.5 rounded inline-block shadow-sm">ID: {selected_node["id"]}</p>
                            <p className="text-sm text-slate-600 font-medium leading-relaxed mt-4">{selected_node["desc"]}</p>
                        </div>
                        <div className="bg-slate-50 border border-slate-200 rounded-2xl p-6 shadow-sm">
                            <h4 className="text-[10px] font-mono font-bold uppercase tracking-widest text-slate-500 mb-3">Live Execution Status</h4>
                            <div className="flex items-center gap-3">
                                <span className={"w-3.5 h-3.5 rounded-full shadow-sm " + str(selected_node["status"] == 2 and "bg-emerald-500 shadow-emerald-500/30" or (selected_node["status"] == 1 and "bg-indigo-500 animate-pulse shadow-indigo-500/40" or (selected_node["status"] == 3 and "bg-amber-500 shadow-amber-500/30" or (selected_node["status"] == 4 and "bg-red-500 shadow-red-500/30" or "bg-slate-300"))))}></span>
                                <span className="text-sm font-bold text-slate-800">
                                    {selected_node["status"] == 0 and "Not reached" or (selected_node["status"] == 1 and "Executing..." or (selected_node["status"] == 2 and "Completed" or (selected_node["status"] == 4 and "Rejected" or "Awaiting approval")))}
                                </span>
                            </div>
                        </div>
                        {selected_node["status"] >= 2 and (
                            <div className={"rounded-2xl p-6 shadow-sm border " + ("bg-red-50 border-red-100" if selected_node["status"] == 4 else "bg-emerald-50 border-emerald-100")}>
                                <h4 className={"text-[10px] font-mono font-extrabold uppercase tracking-widest mb-3 " + ("text-red-600" if selected_node["status"] == 4 else "text-emerald-600")}>Output</h4>
                                <div className={"font-mono text-sm font-medium bg-white p-4 rounded-xl text-wrap break-words leading-relaxed shadow-sm border " + ("text-red-800 border-red-100" if selected_node["status"] == 4 else "text-emerald-800 border-emerald-100")}>
                                    > {selected_node["output"]}
                                </div>
                                <div className="mt-4 pt-4 border-t border-emerald-100 flex items-center justify-between flex-wrap gap-2">
                                    {incident.time and <span className="text-[10px] font-mono text-emerald-600 opacity-70">{incident.time}</span>}
                                    {node_timings[selected_node["id"]] and <span className="text-[10px] font-mono font-bold text-emerald-700 bg-white border border-emerald-200 px-2 py-0.5 rounded-full shadow-sm">{str(node_timings[selected_node["id"]]) + "ms"}</span>}
                                </div>
                            </div>
                        )}
                    </div>
                </div>
            )}

            <style> {".custom-scrollbar::-webkit-scrollbar { width: 8px; height: 8px; }" + ".custom-scrollbar::-webkit-scrollbar-track { background: transparent; }" + ".custom-scrollbar::-webkit-scrollbar-thumb { background: #cbd5e1; border-radius: 4px; }" + ".custom-scrollbar::-webkit-scrollbar-thumb:hover { background: #94a3b8; }" + "@keyframes slide { 0% { transform: translateX(-100%); } 100% { transform: translateX(300%); } }" + "@keyframes slideLeft { from { transform: translateX(100%); } to { transform: translateX(0); } }"} </style>
        </div>
    );
}
