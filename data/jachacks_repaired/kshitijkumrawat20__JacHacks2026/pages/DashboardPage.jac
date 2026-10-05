import from "@jac/runtime" { useNavigate, jacIsLoggedIn, Navigate }
import from ..components.Sidebar { Sidebar }
import from ..services.appService { Goal, Mission, AgentLog, InsightReport, get_missions, toggle_mission, get_stats, get_goals, agent_get_insights, get_agent_logs }

def:pub page() -> JsxElement {
    has missions: list[Mission] = [];
    has goals: list[Goal] = [];
    has stats: dict = {};
    has insights: InsightReport | None = None;
    has agent_logs: list[AgentLog] = [];
    has loading: bool = True;
    has error: str = "";

    navigate = useNavigate();

    if not jacIsLoggedIn() {
        return <Navigate to="/login" replace={True} />;
    }

    async can with entry {
        if jacIsLoggedIn() {
            try {
                missions = await get_missions();
                goals = await get_goals();
                stats = await get_stats();
                agent_logs = await get_agent_logs();
                if len(goals) > 0 {
                    first_goal_id: str = jid(goals[0]);
                    insights = await agent_get_insights(first_goal_id);
                }
            } except Exception as ex {
                error = "Failed to load data";
            }
            loading = False;
        }
    }

    def go_goals(e: MouseEvent) -> None {
        navigate("/goals");
    }

    def go_agents(e: MouseEvent) -> None {
        navigate("/agents");
    }

    async def handle_toggle(mission_id: str) -> None {
        result = await toggle_mission(mission_id);
        if result is not None {
            updated: list[Mission] = [];
            for m in missions {
                if jid(m) == mission_id {
                    updated = updated + [result];
                } else {
                    updated = updated + [m];
                }
            }
            missions = updated;
            stats = await get_stats();
        }
    }

    def make_toggle(mid: str) -> Any {
        def do_toggle(e: MouseEvent) -> None {
            handle_toggle(mid);
        }
        return do_toggle;
    }

    total_goals: int = 0;
    done_count: int = 0;
    total_missions: int = 0;
    total_xp: int = 0;
    avg_progress: int = 0;
    if stats {
        total_goals = int(stats["total_goals"]) if stats["total_goals"] else 0;
        done_count = int(stats["done_missions"]) if stats["done_missions"] else 0;
        total_missions = int(stats["total_missions"]) if stats["total_missions"] else 0;
        total_xp = int(stats["total_xp"]) if stats["total_xp"] else 0;
        avg_progress = int(stats["avg_progress"]) if stats["avg_progress"] else 0;
    }

    agents = [
        {"name": "Planner", "status": "active", "task": "Updating roadmap", "color": "#3b82f6"},
        {"name": "Research", "status": "active", "task": "Scanning opportunities", "color": "#8b5cf6"},
        {"name": "Memory", "status": "idle", "task": "Indexing sessions", "color": "#06b6d4"},
        {"name": "Coach", "status": "active", "task": "Analyzing patterns", "color": "#10b981"},
        {"name": "Execution", "status": "active", "task": "Generating missions", "color": "#f59e0b"},
        {"name": "Analytics", "status": "idle", "task": "Computing report", "color": "#ec4899"}
    ];

    return (
        <div className="page">
            <Sidebar />
            <div className="page-content">
                <div className="page-header">
                    <div>
                        <h1 className="text-2xl font-bold text-foreground">Dashboard ⚡</h1>
                        <p className="text-muted-foreground text-sm mt-1">
                            {str(total_missions - done_count) + " missions pending today" if not loading else "Loading..."}
                        </p>
                    </div>
                    <div className="flex items-center gap-3">
                        <div className="badge-green">
                            <span className="w-1.5 h-1.5 rounded-full bg-green-400 animate-pulse inline-block"></span>
                            <span>4 Agents Active</span>
                        </div>
                        <button className="btn btn-primary" onClick={go_goals}>+ New Goal</button>
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
                            <p className="text-muted-foreground text-sm">AI agents loading your data...</p>
                        </div>
                    </div>
                )}

                {not loading and (
                    <div>
                        <div className="grid grid-cols-4 gap-4 mb-8">
                            <div className="stat-card">
                                <div className="text-xs text-muted-foreground uppercase tracking-wider mb-2">Active Goals</div>
                                <div className="text-3xl font-bold text-gradient-blue">{str(total_goals)}</div>
                                <div className="text-xs text-muted-foreground mt-1">in progress</div>
                            </div>
                            <div className="stat-card">
                                <div className="text-xs text-muted-foreground uppercase tracking-wider mb-2">Total XP</div>
                                <div className="text-3xl font-bold" style={{"color": "#f59e0b"}}>{str(total_xp) + " ⚡"}</div>
                                <div className="text-xs text-muted-foreground mt-1">earned</div>
                            </div>
                            <div className="stat-card">
                                <div className="text-xs text-muted-foreground uppercase tracking-wider mb-2">Missions Done</div>
                                <div className="text-3xl font-bold text-gradient-blue">{str(done_count) + "/" + str(total_missions)}</div>
                                <div className="text-xs text-green-400 mt-1">completed</div>
                            </div>
                            <div className="stat-card">
                                <div className="text-xs text-muted-foreground uppercase tracking-wider mb-2">Avg Progress</div>
                                <div className="text-3xl font-bold" style={{"color": "#8b5cf6"}}>{str(avg_progress) + "%"}</div>
                                <div className="progress-bar mt-2">
                                    <div className="progress-fill" style={{"width": str(avg_progress) + "%"}}></div>
                                </div>
                            </div>
                        </div>

                        <div className="grid grid-cols-3 gap-6">
                            <div className="col-span-2">
                                <div className="card p-5 mb-6">
                                    <div className="flex items-center justify-between mb-4">
                                        <h2 className="text-base font-semibold text-foreground">Missions</h2>
                                        <span className="badge-blue">{str(len(missions)) + " tasks"}</span>
                                    </div>
                                    {len(missions) == 0 and (
                                        <div className="text-center py-8">
                                            <div className="text-3xl mb-2">🎯</div>
                                            <p className="text-muted-foreground text-sm">No missions yet.</p>
                                            <button className="btn btn-primary mt-3 text-sm" onClick={go_goals}>Add a Goal to generate missions</button>
                                        </div>
                                    )}
                                    {len(missions) > 0 and (
                                        <div className="flex flex-col gap-2">
                                            {[
                                                <div key={jid(missions[i])} className="mission-card" onClick={make_toggle(jid(missions[i]))}>
                                                    <div className={"w-5 h-5 rounded-full border-2 flex-shrink-0 mt-0.5 flex items-center justify-center " + ("border-green-400 bg-green-400" if missions[i].done else "border-border")}>
                                                        {missions[i].done and <span style={{"fontSize": "10px", "color": "white"}}>✓</span>}
                                                    </div>
                                                    <div className="flex-1 min-w-0">
                                                        <div className={"text-sm font-medium " + ("line-through text-muted-foreground" if missions[i].done else "text-foreground")}>{missions[i].title}</div>
                                                        <div className="flex items-center gap-2 mt-1">
                                                            <span className="badge-blue text-xs">{missions[i].tag}</span>
                                                            <span className="text-xs text-muted-foreground">{missions[i].difficulty}</span>
                                                        </div>
                                                    </div>
                                                    <div className="text-xs font-medium" style={{"color": "#f59e0b"}}>+{str(missions[i].xp)} XP</div>
                                                </div>
                                                for i in range(len(missions))
                                            ]}
                                        </div>
                                    )}
                                </div>

                                <div className="card p-5">
                                    <div className="flex items-center justify-between mb-4">
                                        <h2 className="text-base font-semibold text-foreground">Your Goals</h2>
                                        <button className="btn btn-ghost text-xs" onClick={go_goals}>Manage →</button>
                                    </div>
                                    {len(goals) == 0 and (
                                        <div className="text-center py-6">
                                            <p className="text-muted-foreground text-sm">No goals yet. Add your first goal!</p>
                                            <button className="btn btn-primary mt-3 text-sm" onClick={go_goals}>+ Add Goal</button>
                                        </div>
                                    )}
                                    {len(goals) > 0 and (
                                        <div className="flex flex-col gap-3">
                                            {[
                                                <div key={jid(goals[i])} className="flex items-center gap-3 p-3 rounded-xl" style={{"background": "rgba(59,130,246,0.04)", "border": "1px solid rgba(59,130,246,0.08)"}}>
                                                    <div className="flex-1 min-w-0">
                                                        <div className="text-sm font-medium text-foreground">{goals[i].title}</div>
                                                        <div className="text-xs text-muted-foreground">{goals[i].timeline}</div>
                                                    </div>
                                                    <div className="text-right">
                                                        <div className="text-sm font-bold text-gradient-blue">{str(goals[i].progress) + "%"}</div>
                                                        <div className="progress-bar w-20 mt-1">
                                                            <div className="progress-fill" style={{"width": str(goals[i].progress) + "%"}}></div>
                                                        </div>
                                                    </div>
                                                </div>
                                                for i in range(len(goals))
                                            ]}
                                        </div>
                                    )}
                                </div>
                            </div>

                            <div>
                                {insights is not None and (
                                    <div className="card p-5 mb-4">
                                        <div className="flex items-center gap-2 mb-4">
                                            <span style={{"fontSize": "14px"}}>🧠</span>
                                            <h2 className="text-base font-semibold text-foreground">AI Insights</h2>
                                            <span className="badge-purple text-xs">Live</span>
                                        </div>
                                        <div className="flex flex-col gap-2 mb-3">
                                            {[
                                                <div key={str(i)} className="flex items-start gap-2 p-2 rounded-lg" style={{"background": "rgba(59,130,246,0.04)"}}>
                                                    <span className="text-xs">💡</span>
                                                    <p className="text-xs text-muted-foreground leading-relaxed">{str(insights.insights[i])}</p>
                                                </div>
                                                for i in range(len(insights.insights))
                                            ]}
                                        </div>
                                        <div className="p-3 rounded-xl" style={{"background": "rgba(16,185,129,0.05)", "border": "1px solid rgba(16,185,129,0.15)"}}>
                                            <p className="text-xs text-green-400 leading-relaxed">{insights.coach_message}</p>
                                        </div>
                                        <div className="flex justify-between mt-3 text-xs">
                                            <span className="text-muted-foreground">Predicted: <span className="text-foreground">{insights.predicted_completion}</span></span>
                                            <span className={"font-medium " + ("text-green-400" if insights.risk_level == "Low" else ("text-yellow-400" if insights.risk_level == "Medium" else "text-red-400"))}>{insights.risk_level} Risk</span>
                                        </div>
                                    </div>
                                )}

                                <div className="card p-5">
                                    <div className="flex items-center justify-between mb-4">
                                        <h2 className="text-base font-semibold text-foreground">Agent Activity</h2>
                                        <div className="flex gap-1">
                                            <span className="typing-dot"></span>
                                            <span className="typing-dot"></span>
                                            <span className="typing-dot"></span>
                                        </div>
                                    </div>
                                    {len(agent_logs) == 0 and (
                                        <div className="text-center py-4">
                                            <p className="text-muted-foreground text-xs">No agent activity yet. Add a goal to activate agents!</p>
                                        </div>
                                    )}
                                    {len(agent_logs) > 0 and (
                                        <div className="flex flex-col gap-2">
                                            {[
                                                <div key={str(i)} className="flex items-start gap-2">
                                                    <div className="w-6 h-6 rounded-md flex items-center justify-center text-xs font-bold flex-shrink-0" style={{"background": "rgba(59,130,246,0.15)", "color": "#60a5fa"}}>
                                                        {agent_logs[len(agent_logs)-1-i].agent_name[:2]}
                                                    </div>
                                                    <div className="flex-1 min-w-0">
                                                        <div className="text-xs font-medium text-foreground">{agent_logs[len(agent_logs)-1-i].agent_name} · {agent_logs[len(agent_logs)-1-i].action}</div>
                                                        {agent_logs[len(agent_logs)-1-i].detail and (
                                                            <div className="text-xs text-muted-foreground truncate">{agent_logs[len(agent_logs)-1-i].detail}</div>
                                                        )}
                                                    </div>
                                                </div>
                                                for i in range(len(agent_logs) if len(agent_logs) < 6 else 6)
                                            ]}
                                        </div>
                                    )}
                                    <button className="btn btn-ghost w-full mt-4 text-xs" onClick={go_agents}>
                                        View full orchestration →
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
}
