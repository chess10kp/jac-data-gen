obj:pub IncidentStep {
    has label: str = "";
    has detail: str = "";
    has time: str = "";
    has state: str = "done";
}

obj:pub IncidentRecord {
    has id: str = "";
    has time: str = "";
    has tenant: str = "";
    has phone: str = "";
    has property: str = "";
    has unit: str = "";
    has category: str = "";
    has urgency: str = "";
    has status: str = "";
    has confidence: str = "";
    has summary: str = "";
    has message: str = "";
    has recommended_action: str = "";
    has owner_notification: str = "";
    has tenant_reply: str = "";
    has automation: str = "";
    has latency: str = "";
    has assignee: str = "";
    has property_code: str = "";
    has steps: list = [];
    has timings: dict = {};
}

def:pub status_classes(value: str) -> str {
    if value == "Resolved" { return "bg-emerald-50 text-emerald-700 border border-emerald-200"; }
    if value == "Owner reviewing" { return "bg-amber-50 text-amber-700 border border-amber-200"; }
    if value == "Dispatching vendor" { return "bg-blue-50 text-blue-700 border border-blue-200"; }
    return "bg-slate-100 text-slate-700 border border-slate-200";
}

def:pub urgency_classes(value: str) -> str {
    if value == "Critical" { return "bg-rose-50 text-rose-700 border border-rose-200"; }
    if value == "High" { return "bg-orange-50 text-orange-700 border border-orange-200"; }
    if value == "Medium" { return "bg-amber-50 text-amber-700 border border-amber-200"; }
    return "bg-slate-100 text-slate-700 border border-slate-200";
}

def:pub category_dot(value: str) -> str {
    if value == "Electrical" { return "bg-rose-500"; }
    if value == "Plumbing" { return "bg-sky-500"; }
    if value == "HVAC" { return "bg-violet-500"; }
    if value == "Appliance" { return "bg-emerald-500"; }
    if value == "Noise" { return "bg-amber-500"; }
    return "bg-slate-500";
}


def:pub empty_state(title: str, description: str, pulse: bool) -> JsxElement {
    return (
        <div className="flex flex-col items-center justify-center py-16 px-4 text-center rounded-sm border border-slate-200 border-dashed bg-slate-50/50">
            <div className="relative mb-4">
                <div className={"w-10 h-10 rounded-full bg-slate-100 border border-slate-200 flex items-center justify-center " + str(pulse and "animate-pulse" or "")}>
                   <div className={"w-3 h-3 rounded-full " + str(pulse and "bg-emerald-500 shadow-[0_0_8px_rgba(16,185,129,0.8)]" or "bg-slate-300")}></div>
                </div>
            </div>
            <h3 className="text-sm font-semibold text-slate-900">{title}</h3>
            <p className="mt-1 text-sm text-slate-500 max-w-sm">{description}</p>
        </div>
    );
}

def:pub nav_button_classes(active: bool) -> str {
    return str(active and "bg-slate-100/80 text-slate-900 font-medium" or "text-slate-500 hover:bg-slate-50 hover:text-slate-900");
}

def:pub panel_classes() -> str {
    return "rounded-sm border border-slate-200 bg-white shadow-sm";
}

def:pub metric_card(title: str, value: str, delta: str, note: str) -> JsxElement {
    return (
        <div className={panel_classes() + " p-5"}>
            <div className="flex items-start justify-between gap-4">
                <div>
                    <p className="text-sm font-medium text-slate-500">{title}</p>
                    <p className="mt-3 text-3xl font-semibold tracking-[-0.03em] text-slate-950">{value}</p>
                </div>
                <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600">{delta}</span>
            </div>
            <p className="mt-3 text-sm leading-6 text-slate-500">{note}</p>
        </div>
    );
}

def:pub sidebar_item(label: str, active: bool, on_click: any, meta: str) -> JsxElement {
    return (
        <button onClick={on_click} className={"w-full rounded-md px-4 py-3 text-left transition-all duration-200 " + nav_button_classes(active)}>
            <div className="flex items-center justify-between gap-3">
                <span className="text-sm font-semibold tracking-[-0.01em]">{label}</span>
                <span className={str(active and "text-white/70 text-xs" or "text-slate-400 text-xs")}>{meta}</span>
            </div>
        </button>
    );
}

def:pub incident_row(incident: IncidentRecord, active: bool, on_click: any, delete_incident: any = None) -> JsxElement {
    return (
        <button onClick={on_click} className={"group flex flex-col gap-2 w-full text-left p-3 rounded-sm border transition-all duration-150 " + str(active and "bg-indigo-50/50 border-indigo-200 shadow-sm" or "bg-white border-slate-200 hover:border-slate-300 hover:bg-slate-50")}>
            <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                    <span className={"w-2 h-2 rounded-full " + category_dot(incident.category)}></span>
                    <span className="text-sm font-semibold text-slate-900">{incident.tenant}</span>
                    <span className="text-xs text-slate-500 font-mono">{incident.id}</span>
                </div>
                <div className="flex items-center gap-2">
                    <span className="text-xs text-slate-400">{incident.time}</span>
                    {delete_incident and (
                        <div onClick={lambda (e: any) -> None { e.stopPropagation(); delete_incident(incident); }} className="hover:text-red-500 text-slate-300 opacity-0 group-hover:opacity-100 transition-opacity p-1">
                            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" /></svg>
                        </div>
                    )}
                </div>
            </div>
            <div className="text-xs text-slate-600 mt-1 mb-2 truncate">
                {incident.message}
            </div>
            <div className="flex items-center justify-between text-xs">
                <div className="text-slate-600">
                    <span className="font-medium text-slate-700">{incident.property}</span>, Unit {incident.unit}
                </div>
                <div className="flex items-center gap-2">
                    <span className={"inline-flex justify-center uppercase tracking-wide border px-1.5 py-0.5 rounded text-[10px] font-bold " + urgency_classes(incident.urgency)}>{incident.urgency}</span>
                    <span className={"inline-flex justify-center border px-1.5 py-0.5 rounded text-[10px] font-semibold " + status_classes(incident.status)}>{incident.status}</span>
                </div>
            </div>
        </button>
    );
}

def:pub timeline_step(step: IncidentStep) -> JsxElement {
    return (
        <div className="flex gap-3">
            <div className="flex flex-col items-center">
                <span className={"mt-1 flex h-3.5 w-3.5 rounded-full border-2 border-white shadow " + str(step.state == "live" and "bg-blue-600" or (step.state == "queued" and "bg-slate-300" or "bg-emerald-500"))}></span>
                <span className="mt-2 h-full w-px bg-slate-200"></span>
            </div>
            <div className="pb-5">
                <div className="flex items-center gap-2">
                    <p className="text-sm font-semibold text-slate-900">{step.label}</p>
                    <span className={"rounded-full px-2 py-0.5 text-[11px] font-semibold uppercase tracking-[0.08em] " + str(step.state == "live" and "bg-blue-50 text-blue-700" or (step.state == "queued" and "bg-slate-100 text-slate-500" or "bg-emerald-50 text-emerald-700"))}>{step.state}</span>
                </div>
                <p className="mt-1 text-sm leading-6 text-slate-500">{step.detail}</p>
                <p className="mt-2 text-xs font-medium text-slate-400">{step.time}</p>
            </div>
        </div>
    );
}

def:pub workflow_node(label: str, detail: str, state: str, active: bool) -> JsxElement {
    return (
        <div className={"relative w-44 rounded-[20px] border p-4 shadow-sm transition-all duration-500 " + str(state == "complete" and "border-emerald-200 bg-emerald-50 text-emerald-900" or (state == "running" and "border-blue-400 bg-white ring-4 ring-blue-50 text-slate-900 shadow-md" or (state == "escalated" and "border-orange-300 bg-orange-50 text-orange-900" or "border-slate-200 bg-slate-50 text-slate-500")))}>
            <div className="flex justify-between">
                <span className={"flex h-6 w-6 items-center justify-center rounded-full text-xs font-bold " + str(state == "complete" and "bg-emerald-500 text-white" or (state == "running" and "bg-blue-500 text-white animate-pulse" or (state == "escalated" and "bg-orange-500 text-white" or "bg-slate-300 text-white")))}>
                    {state == "complete" and "✓" or (state == "running" and "↻" or (state == "escalated" and "!" or "·"))}
                </span>
            </div>
            <p className="mt-3 text-sm font-bold tracking-tight">{label}</p>
            <p className="mt-1 text-xs opacity-80">{detail}</p>
            {active and <div className="absolute -bottom-1 -right-1 flex h-3 w-3 items-center justify-center rounded-full bg-blue-500"><div className="h-full w-full animate-ping rounded-full bg-blue-400 opacity-75"></div></div>}
        </div>
    );
}

def:pub create_incident_record(id: str, time: str, message: str, phone: str, tenant: str, prop: str, unit: str, category: str, urgency: str, status: str, confidence: str, summary: str, owner_notification: str, property_code: str) -> IncidentRecord {
    return IncidentRecord(
        id=id,
        time=time,
        message=message,
        phone=phone,
        tenant=tenant,
        property=prop,
        unit=unit,
        category=category,
        urgency=urgency,
        status=status,
        confidence=confidence,
        summary=summary,
        owner_notification=owner_notification,
        property_code=property_code
    );
}
