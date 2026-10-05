import from "@jac/runtime" { useNavigate, jacIsLoggedIn, Navigate }
import from ..components.Sidebar { Sidebar }
import from ..services.appService { Goal, Mission, MemoryEntry, AgentLog, get_goals, get_missions, get_memories, get_agent_logs, get_stats }

def:pub page() -> JsxElement {
    has goals: list[Goal] = [];
    has missions: list[Mission] = [];
    has memories: list[MemoryEntry] = [];
    has logs: list[AgentLog] = [];
    has stats: dict = {};
    has loading: bool = True;
    has error: str = "";

    navigate = useNavigate();

    if not jacIsLoggedIn() {
        return <Navigate to="/login" replace={True} />;
    }

    async can with entry {
        if jacIsLoggedIn() {
            try {
                goals = await get_goals();
                missions = await get_missions();
                memories = await get_memories();
                logs = await get_agent_logs();
                stats = await get_stats();
            } except Exception as ex {
                error = "Failed to load analytics";
            }
            loading = False;
        }
    }

    total_goals: int = 0;
    total_missions: int = 0;
    done_missions: int = 0;
    total_xp: int = 0;
    avg_progress: int = 0;
    if stats {
        total_goals = int(stats["total_goals"]) if stats["total_goals"] else 0;
        total_missions = int(stats["total_missions"]) if stats["total_missions"] else 0;
        done_missions = int(stats["done_missions"]) if stats["done_missions"] else 0;
        total_xp = int(stats["total_xp"]) if stats["total_xp"] else 0;
        avg_progress = int(stats["avg_progress"]) if stats["avg_progress"] else 0;
    }

    completion_rate: int = 0;
    if total_missions > 0 {
        completion_rate = (done_missions * 100) // total_missions;
    }

    avg_focus: int = 0;
    if len(memories) > 0 {
        total_focus: int = 0;
        for mem in memories {
            total_focus = total_focus + mem.focus_score;
        }
        avg_focus = total_focus // len(memories);
    }

    return (
        <div className="page">
            <Sidebar />
            <div className="page-content">
                <div className="page-header">
                    <div>
                        <h1 className="text-2xl font-bold text-foreground">Analytics</h1>
                        <p className="text-muted-foreground text-sm mt-1">Real-time performance insights from your data</p>
                    </div>
                    <span className="badge-purple">📊 Analytics Agent</span>
                </div>

                {loading and (
                    <div className="flex items-center justify-center py-20">
                        <div className="text-center">
                            <div className="flex gap-2 justify-center mb-3">
                                <span className="typing-dot"></span>
                                <span className="typing-dot"></span>
                                <span className="typing-dot"></span>
                            </div>
                            <p className="text-muted-foreground text-sm">Analytics Agent computing insights...</p>
                        </div>
                    </div>
                )}

                {not loading and (
                    <div>
                        <div className="grid grid-cols-4 gap-4 mb-6">
                            <div className="stat-card">
                                <div className="text-xs text-muted-foreground uppercase tracking-wider mb-2">Active Goals</div>
                                <div className="text-3xl font-bold text-gradient-blue">{str(total_goals)}</div>
                                <div className="text-xs text-muted-foreground mt-1">in progress</div>
                            </div>
                            <div className="stat-card">
                                <div className="text-xs text-muted-foreground uppercase tracking-wider mb-2">Missions Done</div>
                                <div className="text-3xl font-bold text-gradient-blue">{str(done_missions) + "/" + str(total_missions)}</div>
                                <div className="text-xs text-green-400 mt-1">{str(completion_rate) + "% completion"}</div>
                            </div>
                            <div className="stat-card">
                                <div className="text-xs text-muted-foreground uppercase tracking-wider mb-2">Total XP</div>
                                <div className="text-3xl font-bold" style={{"color": "#f59e0b"}}>{str(total_xp) + " ⚡"}</div>
                                <div className="text-xs text-muted-foreground mt-1">earned</div>
                            </div>
                            <div className="stat-card">
                                <div className="text-xs text-muted-foreground uppercase tracking-wider mb-2">Avg Focus</div>
                                <div className="text-3xl font-bold" style={{"color": "#8b5cf6"}}>{str(avg_focus) + "%"}</div>
                                <div className="text-xs text-muted-foreground mt-1">across {str(len(memories))} sessions</div>
                            </div>
                        </div>

                        <div className="grid grid-cols-3 gap-6 mb-6">
                            <div className="col-span-2 card p-5">
                                <h2 className="text-base font-semibold text-foreground mb-4">Goal Progress Overview</h2>
                                {len(goals) == 0 and (
                                    <div className="text-center py-8">
                                        <div className="text-3xl mb-2">🎯</div>
                                        <p className="text-muted-foreground text-sm">No goals yet. Add a goal to see analytics.</p>
                                    </div>
                                )}
                                {len(goals) > 0 and (
                                    <div className="flex flex-col gap-4">
                                        {[
                                            <div key={jid(goals[i])}>
                                                <div className="flex justify-between text-xs mb-1">
                                                    <span className="text-foreground font-medium">{goals[i].title}</span>
                                                    <span className="text-muted-foreground">{goals[i].timeline} · {str(goals[i].progress) + "%"}</span>
                                                </div>
                                                <div className="progress-bar">
                                                    <div className="progress-fill" style={{"width": str(goals[i].progress) + "%"}}></div>
                                                </div>
                                            </div>
                                            for i in range(len(goals))
                                        ]}
                                    </div>
                                )}
                            </div>

                            <div className="card p-5">
                                <h2 className="text-base font-semibold text-foreground mb-4">Mission Breakdown</h2>
                                {total_missions == 0 and (
                                    <div className="text-center py-6">
                                        <p className="text-muted-foreground text-sm">No missions yet.</p>
                                    </div>
                                )}
                                {total_missions > 0 and (
                                    <div>
                                        <div className="flex items-center justify-center mb-4">
                                            <div className="relative w-24 h-24">
                                                <div className="w-24 h-24 rounded-full flex items-center justify-center" style={{"background": "conic-gradient(#3b82f6 " + str(completion_rate * 360 // 100) + "deg, rgba(59,130,246,0.1) 0deg)"}}>
                                                    <div className="w-16 h-16 rounded-full bg-card flex items-center justify-center">
                                                        <span className="text-lg font-bold text-gradient-blue">{str(completion_rate) + "%"}</span>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                        <div className="flex flex-col gap-2">
                                            <div className="flex justify-between text-xs">
                                                <span className="text-green-400">✓ Completed</span>
                                                <span className="text-foreground font-medium">{str(done_missions)}</span>
                                            </div>
                                            <div className="flex justify-between text-xs">
                                                <span className="text-muted-foreground">⏳ Pending</span>
                                                <span className="text-foreground font-medium">{str(total_missions - done_missions)}</span>
                                            </div>
                                            <div className="flex justify-between text-xs">
                                                <span className="text-yellow-400">⚡ Total XP</span>
                                                <span className="text-foreground font-medium">{str(total_xp)}</span>
                                            </div>
                                        </div>
                                    </div>
                                )}
                            </div>
                        </div>

                        <div className="grid grid-cols-2 gap-6">
                            <div className="card p-5">
                                <h2 className="text-base font-semibold text-foreground mb-4">Focus Score History</h2>
                                {len(memories) == 0 and (
                                    <div className="text-center py-6">
                                        <p className="text-muted-foreground text-sm">No sessions logged yet. Complete missions to auto-log sessions.</p>
                                    </div>
                                )}
                                {len(memories) > 0 and (
                                    <div>
                                        <div className="flex items-end gap-1.5 h-24 mb-2">
                                            {[
                                                <div key={str(i)} className="flex-1 rounded-t" style={{"height": str(memories[i].focus_score) + "%", "background": "linear-gradient(to top, #3b82f6, #8b5cf6)", "minHeight": "4px"}}></div>
                                                for i in range(len(memories) if len(memories) < 10 else 10)
                                            ]}
                                        </div>
                                        <div className="text-xs text-muted-foreground text-center">Last {str(len(memories) if len(memories) < 10 else 10)} sessions · Avg: {str(avg_focus)}%</div>
                                    </div>
                                )}
                            </div>

                            <div className="card p-5">
                                <h2 className="text-base font-semibold text-foreground mb-4">Agent Activity Summary</h2>
                                {len(logs) == 0 and (
                                    <div className="text-center py-6">
                                        <p className="text-muted-foreground text-sm">No agent activity yet.</p>
                                    </div>
                                )}
                                {len(logs) > 0 and (
                                    <div className="flex flex-col gap-2">
                                        {[
                                            <div key={str(i)} className="flex items-center gap-2 p-2 rounded-lg" style={{"background": "rgba(59,130,246,0.04)"}}>
                                                <div className="w-6 h-6 rounded-md flex items-center justify-center text-xs font-bold" style={{"background": "rgba(59,130,246,0.2)", "color": "#60a5fa"}}>
                                                    {logs[len(logs)-1-i].agent_name[:2]}
                                                </div>
                                                <div className="flex-1 min-w-0">
                                                    <span className="text-xs font-medium text-foreground">{logs[len(logs)-1-i].agent_name}</span>
                                                    <span className="text-xs text-muted-foreground"> · {logs[len(logs)-1-i].action}</span>
                                                </div>
                                            </div>
                                            for i in range(len(logs) if len(logs) < 5 else 5)
                                        ]}
                                        <div className="text-xs text-muted-foreground text-center mt-1">{str(len(logs))} total agent actions</div>
                                    </div>
                                )}
                            </div>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
}
