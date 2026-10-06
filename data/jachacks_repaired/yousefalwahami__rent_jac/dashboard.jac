
import from shared { empty_state, incident_row, IncidentRecord }

def:pub DashboardView(props: dict) -> JsxElement {
    incidents = props.get("incidents", []);
    selected = props.get("selected", None);
    set_selected = props.get("set_selected", None);
    delete_incident = props.get("delete_incident", None);
    delete_bulk = props.get("delete_bulk", None);
    delete_all = props.get("delete_all", None);

    has selected_ids: list = [];
    has show_confirm: bool = False;
    has confirm_target: any = None;
    has is_deleting: bool = False;
    has toast_msg: str = "";

    def toggle_selection(inc_id: str) -> None {
        if inc_id in selected_ids {
            selected_ids = [x for x in selected_ids if x != inc_id];
        } else {
            selected_ids = selected_ids + [inc_id];
        }
    }

    def toggle_all() -> None {
        if len(selected_ids) == len(incidents) and len(incidents) > 0 {
            selected_ids = [];
        } else {
            selected_ids = [i.id for i in incidents];
        }
    }

    def prompt_delete(inc: any) -> None {
        confirm_target = inc;
        show_confirm = True;
    }

    def prompt_bulk_delete() -> None {
        confirm_target = "bulk";
        show_confirm = True;
    }

    def prompt_delete_all() -> None {
        confirm_target = "all";
        show_confirm = True;
    }

    def close_confirm() -> None {
        show_confirm = False;
        confirm_target = None;
    }

    def show_toast(msg: str) -> None {
        toast_msg = msg;
        setTimeout(lambda () -> None { toast_msg = ""; }, 3000);
    }

    async def execute_delete() -> None {
        is_deleting = True;
        try {
            if confirm_target == "all" {
                if delete_all { delete_all(); }
                selected_ids = [];
                show_toast("Cleared all old messages");
            } elif confirm_target == "bulk" {
                if delete_bulk { delete_bulk(selected_ids); }
                selected_ids = [];
                show_toast("Deleted selected messages");
            } else {
                if delete_incident { delete_incident(confirm_target); }
                if confirm_target.id in selected_ids {
                    selected_ids = [x for x in selected_ids if x != confirm_target.id];
                }
                show_toast("Deleted message " + confirm_target.id);
            }
        } except Exception {
            show_toast("Failed to delete");
        }
        is_deleting = False;
        close_confirm();
    }

    selected_cat = "Unknown";
    if len(incidents) > 0 { selected_cat = incidents[0].category; }
    if selected != None { selected_cat = selected.category; }

    return (
        <div className="flex w-full flex-col p-10 bg-slate-50 min-h-full font-sans relative">
            {toast_msg and (
                <div className="fixed bottom-4 right-4 bg-slate-800 text-white px-4 py-2 rounded shadow-lg text-sm z-50 animate-pop">
                    {toast_msg}
                </div>
            )}

            {show_confirm and (
                <div className="fixed inset-0 bg-slate-900/50 flex items-center justify-center z-50">
                    <div className="bg-white p-6 rounded-lg shadow-xl max-w-sm w-full">
                        <h3 className="text-lg font-bold text-slate-900 mb-2">Confirm Deletion</h3>
                        <p className="text-sm text-slate-500 mb-6">
                            {"Are you sure you want to delete all messages in the feed?" if confirm_target == "all" else ("Are you sure you want to delete " + str(len(selected_ids)) + " selected messages?" if confirm_target == "bulk" else "Are you sure you want to delete this message?")}
                        </p>
                        <div className="flex justify-end gap-3">
                            <button onClick={close_confirm} disabled={is_deleting} className="px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-100 rounded">Cancel</button>
                            <button onClick={execute_delete} disabled={is_deleting} className="px-4 py-2 text-sm font-medium bg-red-600 hover:bg-red-700 text-white rounded shadow-sm opacity-100 disabled:opacity-50">
                                {"Deleting..." if is_deleting else "Delete"}
                            </button>
                        </div>
                    </div>
                </div>
            )}

            <div className="mb-10 flex justify-between items-end">
                <div>
                    <h1 className="text-3xl font-medium tracking-tight text-slate-900 mb-1">Overview</h1>
                    <p className="text-sm text-slate-500 max-w-2xl font-mono tracking-tight">
                        Inbound SMS and active AI triage.
                    </p>
                </div>
                <div className="flex gap-2 items-center">
                    {len(selected_ids) > 0 and (
                        <button onClick={prompt_bulk_delete} className="bg-red-50 hover:bg-red-100 text-red-600 border border-red-200 px-3 py-1.5 rounded-md text-xs font-semibold shadow-sm transition">
                            {"Delete " + str(len(selected_ids)) + " Selected"}
                        </button>
                    )}
                    {len(incidents) > 0 and (
                        <button onClick={prompt_delete_all} className="bg-white hover:bg-slate-100 text-red-600 border border-red-200 px-3 py-1.5 rounded-md text-xs font-semibold shadow-sm transition">
                            Clear All Normal
                        </button>
                    )}
                </div>
            </div>
            
            <div className="grid grid-cols-[1fr_400px] gap-8 flex-1">
                <div className="flex flex-col bg-white rounded-md border border-slate-200 shadow-sm overflow-hidden">
                    <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between bg-slate-50/80">
                        <div className="flex items-center gap-3">
                            <input type="checkbox" checked={len(selected_ids) == len(incidents) and len(incidents) > 0} onChange={toggle_all} className="w-4 h-4 rounded border-slate-300 text-indigo-600 focus:ring-indigo-600" />
                            <div className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></div>
                            <h3 className="text-sm font-medium tracking-tight text-slate-900">Live Incident Feed</h3>
                        </div>
                        <span className="text-[10px] font-mono uppercase tracking-widest text-slate-400">Activity Stream</span>
                    </div>
                    <div className="flex-1 overflow-y-auto p-4 space-y-2 min-h-[400px] bg-slate-50/30">
                        {(empty_state("Waiting for live data", "The incident feed is empty. No SMS messages have been received by the Twilio webhook yet.", True)) if len(incidents) == 0 else 
                            incidents.map(lambda (incident: IncidentRecord) -> JsxElement {
                                is_checked = incident.id in selected_ids;
                                is_sel = False;
                                if selected != None and incident.id == selected.id {
                                    is_sel = True;
                                }
                                return (
                                    <div key={incident.id} className="flex gap-2 items-start group">
                                        <div className={"pt-4 pl-2 opacity-0 group-hover:opacity-100 transition-opacity " + str(is_checked and "opacity-100" or "")}>
                                            <input type="checkbox" checked={is_checked} onChange={lambda (e: any) -> None { toggle_selection(incident.id); }} className="w-4 h-4 rounded border-slate-300 text-indigo-600 focus:ring-indigo-600 cursor-pointer" />
                                        </div>
                                        <div className="flex-1 min-w-0">
                                            {incident_row(incident, is_sel, lambda () -> None { set_selected(incident); }, lambda (i: any) -> None { prompt_delete(i); })}
                                        </div>
                                    </div>
                                );
                            })
                        }
                    </div>
                </div>

                <div className="flex flex-col bg-white rounded-md border border-slate-200 shadow-sm overflow-hidden pointer-events-none">
                    <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between bg-slate-50/80">
                        <div className="flex items-center gap-3">
                            <div className="w-2 h-2 rounded-full bg-indigo-400 animate-pulse"></div>
                            <h3 className="text-sm font-medium tracking-tight text-slate-900">Pending AI Runs</h3>
                        </div>
                        <div className="text-[10px] uppercase tracking-widest font-mono text-slate-400">Queue</div>
                    </div>
                    <div className="flex-1 p-6 relative z-10 flex flex-col items-center justify-center min-h-[400px] bg-slate-50/30">
                        {(
                            <div className="flex flex-col items-center opacity-60">
                                <svg className="w-8 h-8 text-slate-400 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" d="M13 10V3L4 14h7v7l9-11h-7z" /></svg>
                                <p className="text-slate-500 text-xs font-mono text-center tracking-tight">System idle.</p>
                                <p className="text-slate-400 text-xs mt-1 text-center">Awaiting initial Twilio payload.</p>
                            </div>
                        ) if len(incidents) == 0 else (
                            <div className="w-full flex-col flex gap-4 h-full pt-2">
                                <div className="rounded-md border border-slate-200 bg-white shadow-sm p-5">
                                    <div className="flex justify-between items-center mb-3">
                                        <p className="text-[10px] font-mono text-slate-400 uppercase tracking-widest">Processing Thread</p>
                                        <span className="px-2 py-0.5 rounded-full bg-indigo-50 text-indigo-600 text-[10px] font-bold uppercase tracking-wider">Running</span>
                                    </div>
                                    <p className="text-sm text-slate-900 font-semibold truncate">{selected_cat}</p>
                                    <div className="w-full bg-slate-100 h-1.5 mt-4 rounded-full overflow-hidden">
                                        <div className="bg-indigo-500 h-full w-[65%] animate-pulse rounded-full"></div>
                                    </div>
                                    <p className="text-[10px] text-slate-500 mt-3 text-right">Drafting response...</p>
                                </div>
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
}
