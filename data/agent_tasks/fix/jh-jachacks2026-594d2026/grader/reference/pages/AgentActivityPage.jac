import from "@jac/runtime" { useNavigate, jacIsLoggedIn, Navigate }
import from ..components.Sidebar { Sidebar }
import from ..services.appService { AgentLog, get_agent_logs, get_agent_status }

def:pub page() -> JsxElement {
    has logs: list[AgentLog] = [];
    has status: dict = {};
    has loading: bool = True;
    has error: str = "";

    navigate = useNavigate();

    if not jacIsLoggedIn() {
        return <Navigate to="/login" replace={True} />;
    }

    async can with entry {
        if jacIsLoggedIn() {
            try {
                logs = await get_agent_logs();
                status = await get_agent_status();
            } except Exception as ex {
                error = "Failed to load agent data";
            }
            loading = False;
        }
    }

    async def do_refresh() -> None {
        logs = await get_agent_logs();
        status = await get_agent_status();
    }

    def refresh(e: MouseEvent) -> None {
        do_refresh();
    }

    agents = [
        {"key": "planner", "name": "Planner", "icon": "🗺️", "color": "#3b82f6"},
        {"key": "execution", "name": "Execution", "icon": "⚡", "color": "#f59e0b"},
        {"key": "memory", "name": "Memory", "icon": "🧠", "color": "#06b6d4"},
        {"key": "analytics", "name": "Analytics", "icon": "📊", "color": "#ec4899"},
        {"key": "coach", "name": "Coach", "icon": "💪", "color": "#10b981"},
        {"key": "research", "name": "Research", "icon": "🔍", "color": "#8b5cf6"}
    ];

    return (
        <div className="page">
            <Sidebar />
            <div className="page-content">
                <div className="page-header">
                    <div>
                        <h1 className="text-2xl font-bold text-foreground">Agent Orchestration</h1>
                        <p className="text-muted-foreground text-sm mt-1">Live multi-agent AI collaboration — every action is tracked in real-time</p>
                    </div>
                    <div className="flex items-center gap-3">
                        <div className="badge-green">
                            <span className="w-1.5 h-1.5 rounded-full bg-green-400 animate-pulse inline-block"></span>
                            <span>System Online</span>
                        </div>
                        <button className="btn btn-ghost text-xs" onClick={refresh}>↻ Refresh</button>
                    </div>
                </div>

                {loading and (
                    <div className="flex items-center justify-center py-20">
                        <div className="text-center">
                            <div className="flex gap-2 justify-center mb-3">
                                <span className="typing-dot"></span>
                                <span className="typing-dot"></span>
                                <span className="typing-dot"></span>
                            </div>
                            <p className="text-muted-foreground text-sm">Connecting to agent network...</p>
                        </div>
                    </div>
                )}

                {not loading and (
                    <div>
                        <div className="grid grid-cols-3 gap-4 mb-6">
                            {[
                                <div key={str(agents[i]["key"])} className="card p-4">
                                    <div className="flex items-start justify-between mb-3">
                                        <div className="flex items-center gap-2">
                                            <span style={{"fontSize": "20px"}}>{agents[i]["icon"]}</span>
                                            <div>
                                                <div className="text-sm font-semibold text-foreground">{str(agents[i]["name"])} Agent</div>
                                                <div className={"text-xs " + ("text-green-400" if status and str(agents[i]["key"]) in status and str(status[str(agents[i]["key"])]["status"]) == "active" else "text-muted-foreground")}>
                                                    {str(status[str(agents[i]["key"])]["status"]) if status and str(agents[i]["key"]) in status else "idle"}
                                                </div>
                                            </div>
                                        </div>
                                        <div className="w-2 h-2 rounded-full animate-pulse" style={{"background": str(agents[i]["color"]) if status and str(agents[i]["key"]) in status and str(status[str(agents[i]["key"])]["status"]) == "active" else "#6b7280"}}></div>
                                    </div>
                                    <p className="text-xs text-muted-foreground leading-relaxed">
                                        {str(status[str(agents[i]["key"])]["task"]) if status and str(agents[i]["key"]) in status else "Standby"}
                                    </p>
                                    <div className="mt-2 text-xs text-muted-foreground">
                                        Actions: <span className="text-foreground font-medium">{str(status[str(agents[i]["key"])]["tasks_done"]) if status and str(agents[i]["key"]) in status else "0"}</span>
                                    </div>
                                </div>
                                for i in range(len(agents))
                            ]}
                        </div>

                        <div className="grid grid-cols-2 gap-6">
                            <div className="card p-5">
                                <div className="flex items-center justify-between mb-4">
                                    <h2 className="text-base font-semibold text-foreground">Live Activity Feed</h2>
                                    <span className="badge-blue">{str(len(logs))} events</span>
                                </div>
                                {len(logs) == 0 and (
                                    <div className="text-center py-8">
                                        <div className="text-3xl mb-2">🤖</div>
                                        <p className="text-muted-foreground text-sm">No agent activity yet.</p>
                                        <p className="text-muted-foreground text-xs mt-1">Add a goal to see agents spring into action!</p>
                                    </div>
                                )}
                                {len(logs) > 0 and (
                                    <div className="flex flex-col gap-2 max-h-80 overflow-y-auto">
                                        {[
                                            <div key={str(i)} className="flex items-start gap-3 p-2 rounded-lg" style={{"background": "rgba(59,130,246,0.03)"}}>
                                                <div className="w-6 h-6 rounded-md flex items-center justify-center text-xs font-bold flex-shrink-0" style={{"background": "rgba(59,130,246,0.2)", "color": "#60a5fa"}}>
                                                    {logs[len(logs)-1-i].agent_name[:2]}
                                                </div>
                                                <div className="flex-1 min-w-0">
                                                    <div className="flex items-center gap-1">
                                                        <span className="text-xs font-medium text-foreground">{logs[len(logs)-1-i].agent_name}</span>
                                                        <span className="text-xs text-muted-foreground">·</span>
                                                        <span className="text-xs text-muted-foreground">{logs[len(logs)-1-i].action}</span>
                                                    </div>
                                                    {logs[len(logs)-1-i].detail and (
                                                        <p className="text-xs text-muted-foreground truncate">{logs[len(logs)-1-i].detail}</p>
                                                    )}
                                                </div>
                                                <span className="badge-green text-xs flex-shrink-0">{logs[len(logs)-1-i].status}</span>
                                            </div>
                                            for i in range(len(logs))
                                        ]}
                                    </div>
                                )}
                            </div>

                            <div className="card p-5">
                                <h2 className="text-base font-semibold text-foreground mb-4">Agent Network</h2>
                                <div className="relative h-56 flex items-center justify-center">
                                    <div className="absolute inset-0 flex items-center justify-center">
                                        <div className="w-14 h-14 rounded-full flex items-center justify-center text-xs font-bold animate-pulse-glow" style={{"background": "linear-gradient(135deg, rgba(59,130,246,0.3), rgba(139,92,246,0.3))", "border": "2px solid rgba(59,130,246,0.5)", "color": "#60a5fa"}}>
                                            CORE
                                        </div>
                                    </div>
                                    {[
                                        <div
                                            key={str(agents[i]["key"])}
                                            className="absolute w-11 h-11 rounded-full flex items-center justify-center text-xs font-bold"
                                            style={{"background": str(agents[i]["color"]) + "22", "border": "1px solid " + str(agents[i]["color"]) + "66", "color": agents[i]["color"], "top": str([10, 10, 40, 70, 70, 40][i]) + "%", "left": str([40, 65, 80, 65, 40, 15][i]) + "%", "transform": "translate(-50%, -50%)"}}
                                        >
                                            {str(agents[i]["icon"])}
                                        </div>
                                        for i in range(len(agents))
                                    ]}
                                </div>
                                <div className="text-center text-xs text-muted-foreground">
                                    {str(len(logs))} total agent actions recorded
                                </div>
                            </div>
                        </div>

                        <div className="card p-5 mt-6">
                            <h2 className="text-base font-semibold text-foreground mb-3">How Agents Work</h2>
                            <div className="grid grid-cols-3 gap-4">
                                {[
                                    <div key={str(i)} className="p-3 rounded-xl" style={{"background": str(agents[i]["color"]) + "0d", "border": "1px solid " + str(agents[i]["color"]) + "22"}}>
                                        <div className="text-sm font-medium text-foreground mb-1">{str(agents[i]["icon"])} {str(agents[i]["name"])} Agent</div>
                                        <p className="text-xs text-muted-foreground">{["Fires when you add a goal. Generates your roadmap and mission queue automatically.", "Tracks every mission you complete. Awards XP and updates your progress in real-time.", "Auto-logs every completed mission as a memory entry. Builds your learning history.", "Tracks XP, streaks, and completion rates. Generates insights about your performance.", "Monitors your progress milestones. Sends motivational signals at 75% and 100% completion.", "Curates opportunities, courses, and resources tailored to your specific goal."][i]}</p>
                                    </div>
                                    for i in range(len(agents))
                                ]}
                            </div>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
}
