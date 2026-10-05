import from "@jac/runtime" { useNavigate, jacIsLoggedIn, Navigate }
import from ..components.Sidebar { Sidebar }
import from ..services.appService { MemoryEntry, get_memories, add_memory }

def:pub page() -> JsxElement {
    has memories: list[MemoryEntry] = [];
    has loading: bool = True;
    has show_add: bool = False;
    has saving: bool = False;
    has error: str = "";
    has new_summary: str = "";
    has new_tags: str = "";
    has new_focus: str = "80";
    has new_duration: str = "1h";

    navigate = useNavigate();

    if not jacIsLoggedIn() {
        return <Navigate to="/login" replace={True} />;
    }

    async can with entry {
        if jacIsLoggedIn() {
            try {
                memories = await get_memories();
            } except Exception as ex {
                error = "Failed to load memories";
            }
            loading = False;
        }
    }

    async def do_toggle_add() -> None {
        memories = await get_memories();
        show_add = not show_add;
        error = "";
    }

    async def do_cancel_add() -> None {
        memories = await get_memories();
        show_add = False;
    }

    def toggle_add(e: MouseEvent) -> None {
        do_toggle_add();
    }

    def cancel_add(e: MouseEvent) -> None {
        do_cancel_add();
    }

    def handle_summary(e: ChangeEvent) -> None {
        new_summary = e.target.value;
    }

    def handle_tags(e: ChangeEvent) -> None {
        new_tags = e.target.value;
    }

    def handle_focus(e: ChangeEvent) -> None {
        new_focus = e.target.value;
    }

    def handle_duration(e: ChangeEvent) -> None {
        new_duration = e.target.value;
    }

    async def handle_add(e: FormEvent) -> None {
        e.preventDefault();
        saving = True;
        error = "";
        focus_val: int = 80;
        try {
            focus_val = int(new_focus);
        } except Exception as ex {
            focus_val = 80;
        }
        try {
            summary: str = new_summary;
            tags: str = new_tags;
            focus_score: int = focus_val;
            duration: str = new_duration;
            new_entry = await add_memory(summary, tags, focus_score, duration);
            memories = [new_entry] + memories;
            new_summary = "";
            new_tags = "";
            new_focus = "80";
            new_duration = "1h";
            show_add = False;
        } except Exception as ex {
            error = "Failed to save session: " + str(ex);
        }
        saving = False;
    }

    avg_focus: int = 0;
    if len(memories) > 0 {
        total_f: int = 0;
        for m in memories {
            total_f = total_f + m.focus_score;
        }
        avg_focus = total_f // len(memories);
    }

    return (
        <div className="page">
            <Sidebar />
            <div className="page-content">
                <div className="page-header">
                    <div>
                        <h1 className="text-2xl font-bold text-foreground">Memory Timeline</h1>
                        <p className="text-muted-foreground text-sm mt-1">AI-indexed learning history — auto-logged when you complete missions</p>
                    </div>
                    <div className="flex items-center gap-3">
                        <div className="badge-cyan">
                            <span>🧠</span>
                            <span>{str(len(memories)) + " sessions indexed"}</span>
                        </div>
                        <button className="btn btn-primary" onClick={toggle_add}>+ Log Session</button>
                    </div>
                </div>

                {error and <div className="error-box mb-4">{error}</div>}

                {show_add and (
                    <div className="card p-6 mb-6" style={{"border": "1px solid rgba(6,182,212,0.3)"}}>
                        <h2 className="text-base font-semibold text-foreground mb-4">Log a Session</h2>
                        <form onSubmit={handle_add}>
                            <div className="grid grid-cols-2 gap-4 mb-4">
                                <div className="col-span-2">
                                    <label className="label">What did you work on?</label>
                                    <input className="input" type="text" value={new_summary} onChange={handle_summary} placeholder="e.g. Solved 3 LeetCode problems, studied neural networks" />
                                </div>
                                <div>
                                    <label className="label">Tags (comma-separated)</label>
                                    <input className="input" type="text" value={new_tags} onChange={handle_tags} placeholder="DSA, ML, Python" />
                                </div>
                                <div>
                                    <label className="label">Duration</label>
                                    <input className="input" type="text" value={new_duration} onChange={handle_duration} placeholder="e.g. 2h 30m" />
                                </div>
                                <div>
                                    <label className="label">Focus Score (0-100)</label>
                                    <input className="input" type="number" value={new_focus} onChange={handle_focus} placeholder="80" />
                                </div>
                            </div>
                            <div className="flex gap-3">
                                <button type="submit" className="btn btn-primary" disabled={saving}>
                                    {saving and "Saving..." or "Save Session"}
                                </button>
                                <button type="button" className="btn btn-ghost" onClick={cancel_add}>Cancel</button>
                            </div>
                        </form>
                    </div>
                )}

                {loading and (
                    <div className="flex items-center justify-center py-20">
                        <div className="text-center">
                            <div className="flex gap-2 justify-center mb-3">
                                <span className="typing-dot"></span>
                                <span className="typing-dot"></span>
                                <span className="typing-dot"></span>
                            </div>
                            <p className="text-muted-foreground text-sm">Memory Agent loading sessions...</p>
                        </div>
                    </div>
                )}

                {not loading and len(memories) == 0 and not show_add and (
                    <div className="card p-12 text-center">
                        <div className="text-5xl mb-4">🧠</div>
                        <h2 className="text-xl font-semibold text-foreground mb-2">Memory is empty</h2>
                        <p className="text-muted-foreground text-sm mb-2">Sessions are auto-logged when you complete missions.</p>
                        <p className="text-muted-foreground text-sm mb-6">Or log a session manually.</p>
                        <button className="btn btn-primary" onClick={toggle_add}>+ Log Your First Session</button>
                    </div>
                )}

                {not loading and len(memories) > 0 and (
                    <div className="grid grid-cols-3 gap-6">
                        <div className="col-span-2">
                            <h2 className="text-base font-semibold text-foreground mb-4">Session History</h2>
                            <div className="relative">
                                <div className="absolute left-4 top-0 bottom-0 w-px" style={{"background": "rgba(6,182,212,0.2)"}}></div>
                                <div className="flex flex-col gap-4">
                                    {[
                                        <div key={jid(memories[i])} className="flex items-start gap-4 pl-10 relative">
                                            <div className="absolute left-2.5 w-3 h-3 rounded-full border-2" style={{"top": "16px", "background": "#06b6d4", "borderColor": "#06b6d4"}}></div>
                                            <div className="flex-1 card p-4">
                                                <div className="flex items-start justify-between mb-2">
                                                    <div className="flex-1">
                                                        <div className="text-sm font-medium text-foreground">{memories[i].summary}</div>
                                                        <div className="text-xs text-muted-foreground mt-0.5">{memories[i].duration}</div>
                                                    </div>
                                                    <div className="text-right ml-4">
                                                        <div className="text-sm font-bold" style={{"color": "#06b6d4"}}>{str(memories[i].focus_score) + "%"}</div>
                                                        <div className="text-xs text-muted-foreground">focus</div>
                                                    </div>
                                                </div>
                                                {memories[i].tags and (
                                                    <div className="flex gap-1 flex-wrap">
                                                        {[
                                                            <span key={str(j)} className="badge-cyan text-xs">{tag.strip()}</span>
                                                            for (j, tag) in enumerate(str(memories[i].tags).split(","))
                                                            if tag.strip()
                                                        ]}
                                                    </div>
                                                )}
                                            </div>
                                        </div>
                                        for i in range(len(memories))
                                    ]}
                                </div>
                            </div>
                        </div>

                        <div>
                            <div className="card p-5">
                                <h2 className="text-base font-semibold text-foreground mb-4">Memory Stats</h2>
                                <div className="flex flex-col gap-4">
                                    <div>
                                        <div className="text-xs text-muted-foreground mb-1">Total Sessions</div>
                                        <div className="text-2xl font-bold text-gradient-blue">{str(len(memories))}</div>
                                    </div>
                                    <div>
                                        <div className="text-xs text-muted-foreground mb-1">Avg Focus Score</div>
                                        <div className="text-2xl font-bold" style={{"color": "#06b6d4"}}>{str(avg_focus) + "%"}</div>
                                        <div className="progress-bar mt-1">
                                            <div className="progress-fill" style={{"width": str(avg_focus) + "%"}}></div>
                                        </div>
                                    </div>
                                    <div className="p-3 rounded-xl" style={{"background": "rgba(6,182,212,0.05)", "border": "1px solid rgba(6,182,212,0.1)"}}>
                                        <div className="text-xs font-medium mb-1" style={{"color": "#22d3ee"}}>🧠 Memory Agent</div>
                                        <p className="text-xs text-muted-foreground">Auto-logs every completed mission. Building your learning history.</p>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
}
