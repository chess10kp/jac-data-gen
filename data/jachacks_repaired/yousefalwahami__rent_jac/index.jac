import from "@jac/runtime" { __doFuncFetch, __doWalkerFetch, jacIsLoggedIn, jacLogout }
import from .dashboard { DashboardView }
import from .tenants_properties { TenantsPropertiesView }
import from .incidents { IncidentsView }
import from .settings { SettingsView }
import from .login { LoginView }
import from .shared { nav_button_classes, IncidentRecord, create_incident_record }

def:pub ClientApp() -> JsxElement {
    has is_authenticated: bool = jacIsLoggedIn();
    has current_view: str = "Dashboard";
    has live_incidents: list = [];
    has selected_incident: any = None;
    has search: str = "";
    has urgency_filter: str = "All";
    has category_filter: str = "All";
    has loading_live: bool = False;
    has initial_load: bool = False;
    has sidebar_collapsed: bool = False;
    has viewing_detail: bool = False;
    has _triaged_sids: any = {};
    has _triage_cache: any = {};

    def build_incidents_list(msgs: list) -> list {
        result = [];
        ctr = 1000;
        for msg in msgs {
            # Landlord alert number is not a tenant — exclude from incident list
            if str(msg["from"]) == "+15199992505" { ctr += 1; continue; }
            t_name = str(msg["tenant_name"]) if msg["matched"] else str(msg["from"]);
            p_name = str(msg["property_name"]) if msg["matched"] else "Unknown Property";
            u_name = str(msg["unit"]) if msg["matched"] else "?";
            id_val = str(msg["sid"]) if msg["sid"] else str(ctr);

            triage_data = msg["triage"] if ("triage" in msg and msg["triage"]) else None;
            maint_result = None;
            if triage_data and triage_data["event_type"] == "maintenance" and triage_data["result"] {
                maint_result = triage_data["result"];
            }

            inc_category = "Incoming SMS";
            inc_urgency = "Normal";
            inc_status = "Open";
            inc_summary: any = "Awaiting AI Triage...";
            inc_tenant: any = t_name;
            inc_property: any = p_name;
            inc_unit: any = u_name;
            inc_owner_note: any = "Tenant " + t_name + " sent a message: " + str(msg["body"]);
            inc_assignee: any = "";
            inc_tenant_reply: any = "";
            inc_recommended: any = "";
            inc_confidence = "0%";
            inc_property_code = "??";

            if maint_result {
                inc_category = str(maint_result["category"]).split(".")[-1] if maint_result["category"] else "Maintenance";
                if inc_category { inc_category = inc_category[0].upper() + inc_category[1:]; }
                inc_urgency = str(maint_result["urgency"]).split(".")[-1] if maint_result["urgency"] else "Medium";
                if inc_urgency { inc_urgency = inc_urgency[0].upper() + inc_urgency[1:]; }
                inc_status = str(maint_result["status"]) if maint_result["status"] else "pending_approval";
                inc_summary = maint_result["diagnosis"] if maint_result["diagnosis"] else "";
                inc_tenant = maint_result["tenant"] if maint_result["tenant"] else t_name;
                inc_property = maint_result["property"] if maint_result["property"] else p_name;
                inc_unit = maint_result["unit"] if maint_result["unit"] else u_name;
                inc_owner_note = maint_result["owner_alert"] if maint_result["owner_alert"] else "";
                inc_assignee = maint_result["vendor"] if maint_result["vendor"] else "";
                inc_tenant_reply = maint_result["tenant_reply"] if maint_result["tenant_reply"] else "";
                inc_recommended = maint_result["recommended_action"] if maint_result["recommended_action"] else "";
                inc_confidence = "95%";
                inc_property_code = inc_property[0:2].upper() + "-" + inc_unit if inc_property and inc_property != "Unknown Property" else "??";
            } elif triage_data and triage_data["event_type"] == "maintenance" {
                # Phase 1 complete: diagnosis done, vendor search in progress
                inc_category = str(triage_data["category"]).split(".")[-1] if triage_data["category"] else "Maintenance";
                if inc_category { inc_category = inc_category[0].upper() + inc_category[1:]; }
                inc_urgency = str(triage_data["urgency"]).split(".")[-1] if triage_data["urgency"] else "Medium";
                if inc_urgency { inc_urgency = inc_urgency[0].upper() + inc_urgency[1:]; }
                inc_status = "Processing";
                inc_summary = triage_data["summary"] if triage_data["summary"] else "Searching for vendors...";
                if triage_data["tenant"] { inc_tenant = str(triage_data["tenant"]); }
                if triage_data["property"] { inc_property = str(triage_data["property"]); }
                if triage_data["unit"] { inc_unit = str(triage_data["unit"]); }
                inc_confidence = "85%";
            } elif triage_data and triage_data["event_type"] {
                event_name = str(triage_data["event_type"]);
                inc_category = event_name[0].upper() + event_name[1:];
                inc_status = "Classified";
                inc_summary = "Classified as " + event_name;
                if triage_data["tenant"] { inc_tenant = str(triage_data["tenant"]); }
                if triage_data["property"] { inc_property = str(triage_data["property"]); }
                if triage_data["unit"] { inc_unit = str(triage_data["unit"]); }
                inc_confidence = "90%";
            }

            inc: any = create_incident_record("INC-" + id_val, str(msg["time"]), str(msg["body"]), str(msg["from"]), inc_tenant, inc_property, inc_unit, inc_category, inc_urgency, inc_status, inc_confidence, inc_summary, inc_owner_note, inc_property_code);
            inc.recommended_action = inc_recommended;
            inc.tenant_reply = inc_tenant_reply;
            inc.assignee = inc_assignee;
            if maint_result and "timings" in maint_result {
                inc.timings = maint_result["timings"];
            } elif triage_data and "timings" in triage_data {
                inc.timings = triage_data["timings"];
            }
            result.append(inc);
            ctr += 1;
        }
        return result;
    }

    def save_triage_cache() -> None {
        try { localStorage.setItem("rentora_triage_cache", JSON.stringify(_triage_cache)); } except Exception {}
    }

    async def run_triage_bg(msg: dict, sid: str, msgs: list) -> None {
        # Landlord alert number is not a tenant — never create tickets for it
        if str(msg["from"]) == "+15199992505" { return; }
        # Phase 1: fast diagnosis (~500ms) — updates urgency/entity/classification immediately
        try {
            p1 = await __doWalkerFetch("maintenance_phase1", "", {"body": str(msg["body"]), "from_number": str(msg["from"])});
            console.log("[phase1] reports=", p1["reports"]);
            if p1 and p1["reports"] and p1["reports"][0] and p1["reports"][0]["step"] == "diagnosed" {
                d = p1["reports"][0];
                partial = {
                    "status": "processing",
                    "event_type": "maintenance",
                    "tenant": d["tenant"],
                    "property": d["property"],
                    "unit": d["unit"],
                    "category": d["category"],
                    "urgency": d["urgency"],
                    "summary": d["summary"],
                    "recommended_action": d["recommended_action"],
                    "result": None,
                    "timings": d["timings"]
                };
                msg["triage"] = partial;
                if sid { _triage_cache[sid] = partial; save_triage_cache(); }
                live_incidents = build_incidents_list(msgs);
            }
        } except Exception {}

        # Phase 2: full pipeline — LLM calls take ~2-3s naturally, vendor data is instant
        try {
            tr = await __doWalkerFetch("run_maintenance_direct", "", {"body": str(msg["body"]), "from_number": str(msg["from"])});
            console.log("[run_maintenance_direct] reports=", tr["reports"]);
            triage_val = None;
            if tr and tr["reports"] and tr["reports"][0] {
                raw = tr["reports"][0];
                if raw["ticket_id"] {
                    triage_val = {
                        "status": "processed",
                        "event_type": "maintenance",
                        "tenant": raw["tenant"],
                        "property": raw["property"],
                        "unit": raw["unit"],
                        "result": raw,
                        "timings": raw["timings"] if "timings" in raw else {}
                    };
                    await __doFuncFetch("send_maintenance_alert", {"maint_result": raw, "msg_sid": sid});
                } elif not raw["success"] {
                    console.log("[run_maintenance_direct] failed:", raw["error"]);
                }
            }
            if triage_val { msg["triage"] = triage_val; }
            if triage_val and sid { _triage_cache[sid] = triage_val; save_triage_cache(); }
            live_incidents = build_incidents_list(msgs);
            # Auto-approve 5 seconds after vendor is matched
            if triage_val and sid and triage_val["result"] and triage_val["result"]["vendor"] {
                setTimeout(lambda () -> None {
                    if _triage_cache[sid] and _triage_cache[sid]["result"] {
                        _triage_cache[sid]["result"]["status"] = "Approved";
                        save_triage_cache();
                        live_incidents = build_incidents_list(msgs);
                    }
                }, 5000);
            }
        } except Exception {}
    }

    async def load_live_data() -> None {
        if not jacIsLoggedIn() {
            loading_live = False;
            return;
        }
        loading_live = True;
        try {
            raw_res = await __doFuncFetch("get_messages", {});
            messages = [];
            if raw_res and raw_res["messages"] {
                messages = raw_res["messages"];
            } elif raw_res and raw_res["data"] and raw_res["data"]["result"] and raw_res["data"]["result"]["messages"] {
                messages = raw_res["data"]["result"]["messages"];
            }
            
            # Allow clearing list if empty
            if raw_res and raw_res["data"] and raw_res["data"]["result"] and len(raw_res["data"]["result"]["messages"] if raw_res["data"]["result"]["messages"] else []) == 0 {
                messages = [];
            }

            # Client-side phone matching from localStorage tenants
            ls_tenants: any = [];
            try {
                raw_t = localStorage.getItem("rentora_tenants");
                if raw_t { ls_tenants = JSON.parse(raw_t); }
            } except Exception {}
            for msg in messages {
                matched = False;
                for t in ls_tenants {
                    if str(t["phone_number"]) == str(msg["from"]) {
                        msg["matched"] = True;
                        msg["tenant_name"] = t["full_name"];
                        msg["property_name"] = t["property_name"] if t["property_name"] else "Unknown Property";
                        msg["unit"] = t["unit_number"];
                        matched = True;
                        break;
                    }
                }
                if not matched {
                    msg["matched"] = False;
                    msg["tenant_name"] = "";
                    msg["property_name"] = "";
                    msg["unit"] = "";
                }
            }

            # Sync triage cache with server — server terminals (Approved/Rejected from SMS) take priority;
            # client terminals (auto-approve timer) are preserved if server hasn't set one yet
            _terminal = ["Approved", "Rejected", "Resolved"];
            cache_dirty = False;
            for msg in messages {
                sid = str(msg["sid"]) if msg["sid"] else "";
                if sid and msg["triage"] {
                    server_status = None;
                    if msg["triage"]["result"] and msg["triage"]["result"]["status"] {
                        server_status = str(msg["triage"]["result"]["status"]);
                    }
                    cached_status = None;
                    if _triage_cache[sid] and _triage_cache[sid]["result"] and _triage_cache[sid]["result"]["status"] {
                        cached_status = str(_triage_cache[sid]["result"]["status"]);
                    }
                    if server_status in _terminal or cached_status not in _terminal {
                        # Server has definitive state OR cache has no terminal state — use server
                        _triage_cache[sid] = msg["triage"];
                        cache_dirty = True;
                    } else {
                        # Cache has terminal state (auto-approved), server doesn't — keep cache, restore to msg
                        msg["triage"] = _triage_cache[sid];
                    }
                } elif sid and not msg["triage"] and _triage_cache[sid] {
                    msg["triage"] = _triage_cache[sid];
                }
            }
            if cache_dirty { save_triage_cache(); }

            # Auto-run triage once per SID per session (prevents rate limit spam)
            needs_triage = [];
            for msg in messages {
                sid = str(msg["sid"]) if msg["sid"] else "";
                if sid and not msg["triage"] and not _triaged_sids[sid] {
                    needs_triage.append(msg);
                    _triaged_sids[sid] = True;
                }
            }
            # Fire triage for each new message in the background — non-blocking
            for msg in needs_triage {
                run_triage_bg(msg, str(msg["sid"]) if msg["sid"] else "", messages);
            }
            live_incidents = build_incidents_list(messages);
        } except Exception as ex {
            print("Failed to sync live data: " + str(ex));
        }
        loading_live = False;
    }

    has user_name: str = localStorage.getItem("rentora_name") or "";
    has user_email: str = localStorage.getItem("rentora_email") or "";

    async can with entry {
        if is_authenticated {
            user_name = localStorage.getItem("rentora_name") or "";
            user_email = localStorage.getItem("rentora_email") or "";
        }
        if not initial_load {
            initial_load = True;
            # Restore triage cache from localStorage before first poll
            try {
                raw_cache = localStorage.getItem("rentora_triage_cache");
                if raw_cache { _triage_cache = JSON.parse(raw_cache); }
            } except Exception {}
            setTimeout(load_live_data, 2000);
            setInterval(lambda () -> None {
                if not loading_live {
                    load_live_data();
                }
            }, 10000);
        }
    }

    if not is_authenticated {
        return <LoginView on_auth_success={lambda () -> None { is_authenticated = True; }} />;
    }

    def handle_logout() -> None {
        jacLogout();
        is_authenticated = False;
    }

    def set_selected(item: IncidentRecord) -> None {
        selected_incident = item;
    }

    def content() -> JsxElement {
        if current_view == "Dashboard" { 
            return <DashboardView 
                incidents={live_incidents} 
                selected={selected_incident} 
                set_selected={set_selected} 
                delete_incident={lambda (inc: any) -> None {
                    __doFuncFetch("delete_message", {"msg_id": inc.id});
                    setTimeout(load_live_data, 300);
                }}
                delete_bulk={lambda (ids: any) -> None {
                    for i in ids {
                        __doFuncFetch("delete_message", {"msg_id": i});
                    }
                    setTimeout(load_live_data, 300);
                }}
                delete_all={lambda () -> None {
                    for i in live_incidents {
                        __doFuncFetch("delete_message", {"msg_id": i.id});
                    }
                    setTimeout(load_live_data, 300);
                }}
            />; 
        }
        if current_view == "Incidents" { return <IncidentsView incidents={live_incidents} selected={selected_incident} set_selected={set_selected} search={search} set_search={lambda (value: str) -> None { search = value; }} urgency_filter={urgency_filter} set_urgency={lambda (value: str) -> None { urgency_filter = value; }} category_filter={category_filter} set_category={lambda (value: str) -> None { category_filter = value; }} viewing_detail={viewing_detail} set_viewing_detail={lambda (v: bool) -> None { viewing_detail = v; }} />; }
                if current_view == "Tenants & Properties" { return <TenantsPropertiesView />; }
        return <SettingsView />;
    }

    def sidebar_item(label: str, icon: any, active: bool, on_click: any, meta: str) -> JsxElement {
        return (
            <button
                onClick={on_click}
                className={"flex w-full items-center rounded-sm px-3 py-2 text-[13px] transition-colors gap-3 " + str(active and "bg-slate-900 text-white font-medium shadow-sm" or "text-slate-600 hover:bg-slate-100 hover:text-slate-900 font-medium") + str(sidebar_collapsed and " justify-center" or " justify-between")}
                title={label if sidebar_collapsed else ""}
            >
                <div className="flex items-center gap-3">
                    <span className="shrink-0">{icon}</span>
                    {not sidebar_collapsed and <span>{label}</span>}
                </div>
                {meta and not sidebar_collapsed and (
                    <span className={"text-[10px] uppercase font-mono tracking-widest " + str(active and "text-slate-400" or "text-slate-400")}>
                        {meta}
                    </span>
                )}
            </button>
        );
    }

    icon_dashboard = <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="7" height="9"></rect><rect x="14" y="3" width="7" height="5"></rect><rect x="14" y="12" width="7" height="9"></rect><rect x="3" y="16" width="7" height="5"></rect></svg>;
    icon_incidents = <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>;
    icon_tenants_props = <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path><polyline points="9 22 9 12 15 12 15 22"></polyline></svg>;
    icon_settings = <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="3"></circle><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33h.09a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"></path></svg>;

    title_text = current_view;

    return (
        <div className="flex h-screen w-full bg-slate-50 text-slate-900 font-sans overflow-hidden font-inter selection:bg-indigo-100 selection:text-indigo-900">
            
            <aside className={"flex-shrink-0 border-r border-slate-200 bg-slate-50/50 flex flex-col justify-between transition-all duration-300 " + str(sidebar_collapsed and "w-[72px]" or "w-[260px]")}>
                <div className={"px-4 py-5" + str(sidebar_collapsed and " flex flex-col items-center" or "")}>
                    
                    <div className={"flex items-center mb-6 " + str(sidebar_collapsed and "justify-center" or "justify-between")}>
                        <div className={"flex items-center gap-3 cursor-pointer group " + str(sidebar_collapsed and "justify-center" or "px-2")}>
                            <div className="flex h-8 w-8 items-center justify-center rounded-md bg-slate-900 text-white text-sm font-semibold shadow-sm group-hover:bg-slate-800 transition-colors shrink-0">
                                R
                            </div>
                            {not sidebar_collapsed and (
                                <div>
                                    <h1 className="text-[14px] font-semibold tracking-tight text-slate-900">Rentora</h1>
                                    <p className="text-[12px] text-slate-500 line-clamp-1">Production Environment</p>
                                </div>
                            )}
                        </div>
                        <button onClick={lambda () -> None { sidebar_collapsed = not sidebar_collapsed; }} className="text-slate-400 hover:text-slate-700 p-1 rounded-md hover:bg-slate-100 transition" title={str(sidebar_collapsed and "Expand sidebar" or "Collapse sidebar")}>
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                <line x1="3" y1="12" x2="21" y2="12"></line>
                                <line x1="3" y1="6" x2="21" y2="6"></line>
                                <line x1="3" y1="18" x2="21" y2="18"></line>
                            </svg>
                        </button>
                    </div>

                    
                    <div className="space-y-1 w-full">
                        {sidebar_item("Dashboard", icon_dashboard, current_view == "Dashboard", lambda () -> None { current_view = "Dashboard"; }, "Live")}
                        {sidebar_item("Incidents", icon_incidents, current_view == "Incidents", lambda () -> None { current_view = "Incidents"; }, str(len(live_incidents)))}
                        {sidebar_item("Tenants & Properties", icon_tenants_props, current_view == "Tenants & Properties", lambda () -> None { current_view = "Tenants & Properties"; }, "")}
                        {sidebar_item("Settings", icon_settings, current_view == "Settings", lambda () -> None { current_view = "Settings"; }, "")}
                    </div>
                </div>

                <div className={"p-4 border-t border-slate-200/60" + str(sidebar_collapsed and " flex flex-col items-center" or "")}>
                    <div className={"flex items-center justify-between gap-2 py-2 " + str(not sidebar_collapsed and "px-2" or "")}>
                        <div className="flex items-center gap-2 min-w-0" title={user_name if user_name else user_email if user_email else "Account"}>
                            <div className="w-7 h-7 rounded-full bg-slate-900 flex items-center justify-center text-white text-xs font-semibold shrink-0 border border-slate-300">
                                {(user_name[0].upper() if user_name else user_email[0].upper() if user_email else "?")}
                            </div>
                            {not sidebar_collapsed and (
                                <div className="min-w-0">
                                    <p className="text-sm font-medium text-slate-900 truncate">{user_name if user_name else user_email if user_email else "Account"}</p>
                                    {user_name and user_email and <p className="text-xs text-slate-500 truncate">{user_email}</p>}
                                </div>
                            )}
                        </div>
                        {not sidebar_collapsed and (
                            <button
                                onClick={handle_logout}
                                className="text-xs font-medium text-slate-500 hover:text-slate-900 px-2 py-1 rounded-md hover:bg-slate-100 transition shrink-0"
                            >
                                Sign out
                            </button>
                        )}
                    </div>
                    {sidebar_collapsed and (
                        <button
                            onClick={handle_logout}
                            title="Sign out"
                            className="mt-2 text-xs font-medium text-slate-500 hover:text-slate-900 p-2 rounded-md hover:bg-slate-100 transition shrink-0 flex justify-center"
                        >
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path><polyline points="16 17 21 12 16 7"></polyline><line x1="21" y1="12" x2="9" y2="12"></line></svg>
                        </button>
                    )}
                </div>
            </aside>

            
            <main className="flex-1 flex flex-col min-w-0 bg-white">
                
                <header className="h-14 flex-shrink-0 border-b border-slate-200 flex items-center justify-between px-6 bg-white">
                    <div className="flex items-center gap-3">
                        {viewing_detail and current_view == "Incidents" and selected_incident and (
                            <button onClick={lambda () -> None { viewing_detail = False; }} className="text-slate-500 hover:text-slate-900 focus:outline-none p-1 rounded-md hover:bg-slate-100 transition">
                                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M19 12H5"></path><path d="M12 19l-7-7 7-7"></path></svg>
                            </button>
                        )}
                        {viewing_detail and current_view == "Incidents" and selected_incident and (
                            <div className="flex items-center gap-1 text-sm">
                                <span onClick={lambda () -> None { viewing_detail = False; }} className="font-medium text-slate-500 hover:text-slate-900 hover:underline cursor-pointer transition-colors">Incidents</span>
                                <span className="text-slate-300 mx-1">/</span>
                                <span className="font-semibold text-slate-900">{selected_incident.id}</span>
                            </div>
                        )}
                        {(not viewing_detail or current_view != "Incidents" or not selected_incident) and (
                            <h2 className="text-sm font-medium text-slate-900">{title_text}</h2>
                        )}
                    </div>
                    

                    <div className="flex items-center gap-4">
                        {viewing_detail and current_view == "Incidents" and selected_incident and (
                            <div className="flex text-xs text-slate-600 gap-4 border border-slate-200 bg-white shadow-sm px-3 py-1.5 rounded-lg">
                                <div className="flex items-center gap-1.5">
                                    <span className="text-[9px] text-slate-400 uppercase font-bold tracking-wider">Urgency</span>
                                    <span className="font-semibold text-rose-600">{selected_incident.urgency}</span>
                                </div>
                                <div className="w-px bg-slate-200"></div>
                                <div className="flex items-center gap-1.5">
                                    <span className="text-[9px] text-slate-400 uppercase font-bold tracking-wider">Property</span>
                                    <span className="font-semibold text-slate-800">{selected_incident.property} {selected_incident.unit}</span>
                                </div>
                                <div className="w-px bg-slate-200"></div>
                                <div className="flex items-center gap-1.5">
                                    <span className="text-[9px] text-slate-400 uppercase font-bold tracking-wider">Status</span>
                                    <span className="font-semibold text-slate-800">{selected_incident.status}</span>
                                </div>
                            </div>
                        )}
                        <button 
                            onClick={load_live_data} 
                            disabled={loading_live}
                            className="bg-indigo-50 hover:bg-indigo-100 text-indigo-700 border border-indigo-200 px-3 py-1.5 rounded-md text-xs font-semibold shadow-sm transition disabled:opacity-50"
                        >
                            {("Syncing..." if loading_live else "Sync Live Data")}
                        </button>
                        <div className="text-[10px] font-mono text-slate-400 uppercase tracking-widest px-2 py-1 bg-slate-100 rounded-sm">
                            Rentora OS v1
                        </div>
                    </div>

                </header>

                
                <div className="flex-1 overflow-y-auto">
                    {content()}
                </div>
            </main>
        </div>
    );
}
