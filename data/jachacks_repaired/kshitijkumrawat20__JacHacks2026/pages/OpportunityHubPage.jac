import from "@jac/runtime" { useNavigate, jacIsLoggedIn, Navigate }
import from ..components.Sidebar { Sidebar }
import from ..services.appService { Goal, OpportunityReport, get_goals, agent_get_opportunities }

def:pub page() -> JsxElement {
    has active_tab: str = "internships";
    has goals: list[Goal] = [];
    has opportunities: OpportunityReport | None = None;
    has loading: bool = True;
    has generating: bool = False;
    has error: str = "";

    navigate = useNavigate();

    if not jacIsLoggedIn() {
        return <Navigate to="/login" replace={True} />;
    }

    async can with entry {
        if jacIsLoggedIn() {
            try {
                goals = await get_goals();
                if len(goals) > 0 {
                    first_id: str = jid(goals[0]);
                    opportunities = await agent_get_opportunities(first_id);
                }
            } except Exception as ex {
                error = "Failed to load opportunities";
            }
            loading = False;
        }
    }

    async def do_set_internships() -> None {
        goals = await get_goals();
        active_tab = "internships";
    }

    async def do_set_courses() -> None {
        goals = await get_goals();
        active_tab = "courses";
    }

    async def do_set_projects() -> None {
        goals = await get_goals();
        active_tab = "projects";
    }

    async def do_set_networking() -> None {
        goals = await get_goals();
        active_tab = "networking";
    }

    async def do_refresh() -> None {
        generating = True;
        goals = await get_goals();
        if len(goals) > 0 {
            first_id: str = jid(goals[0]);
            opportunities = await agent_get_opportunities(first_id);
        }
        generating = False;
    }

    def set_internships(e: MouseEvent) -> None {
        do_set_internships();
    }

    def set_courses(e: MouseEvent) -> None {
        do_set_courses();
    }

    def set_projects(e: MouseEvent) -> None {
        do_set_projects();
    }

    def set_networking(e: MouseEvent) -> None {
        do_set_networking();
    }

    def refresh(e: MouseEvent) -> None {
        do_refresh();
    }

    def go_goals(e: MouseEvent) -> None {
        navigate("/goals");
    }

    return (
        <div className="page">
            <Sidebar />
            <div className="page-content">
                <div className="page-header">
                    <div>
                        <h1 className="text-2xl font-bold text-foreground">Opportunity Hub</h1>
                        <p className="text-muted-foreground text-sm mt-1">AI-curated opportunities matched to your goals</p>
                    </div>
                    <div className="flex items-center gap-3">
                        <div className="badge-purple">
                            <span>🔍</span>
                            <span>Research Agent</span>
                        </div>
                        {len(goals) > 0 and (
                            <button className="btn btn-ghost text-xs" onClick={refresh}>
                                {generating and "Scanning..." or "↻ Refresh"}
                            </button>
                        )}
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
                            <p className="text-muted-foreground text-sm">Research Agent scanning opportunities...</p>
                        </div>
                    </div>
                )}

                {not loading and len(goals) == 0 and (
                    <div className="card p-12 text-center">
                        <div className="text-5xl mb-4">🚀</div>
                        <h2 className="text-xl font-semibold text-foreground mb-2">No goals yet</h2>
                        <p className="text-muted-foreground text-sm mb-6">Add a goal first — the Research Agent will find personalized opportunities for you.</p>
                        <button className="btn btn-primary" onClick={go_goals}>+ Add a Goal</button>
                    </div>
                )}

                {not loading and len(goals) > 0 and opportunities is None and (
                    <div className="card p-12 text-center">
                        <div className="text-5xl mb-4">🔍</div>
                        <h2 className="text-xl font-semibold text-foreground mb-2">Scanning opportunities...</h2>
                        <p className="text-muted-foreground text-sm">The Research Agent is analyzing your goal.</p>
                    </div>
                )}

                {not loading and opportunities is not None and (
                    <div>
                        {len(goals) > 0 and (
                            <div className="card p-4 mb-6" style={{"border": "1px solid rgba(139,92,246,0.2)", "background": "rgba(139,92,246,0.04)"}}>
                                <div className="flex items-center justify-between">
                                    <div className="flex items-center gap-2">
                                        <span>🎯</span>
                                        <span className="text-sm font-medium text-foreground">Opportunities for: </span>
                                        <span className="text-sm text-muted-foreground">{goals[0].title}</span>
                                    </div>
                                    <div className="flex items-center gap-2">
                                        <span className="badge-green text-xs">🌐 Live Web Search</span>
                                        <span className="text-xs text-muted-foreground">Research Agent crawled the web</span>
                                    </div>
                                </div>
                            </div>
                        )}

                        <div className="flex gap-2 mb-6">
                            <button className={"btn text-sm " + ("btn-primary" if active_tab == "internships" else "btn-ghost")} onClick={set_internships}>
                                🏢 Internships
                            </button>
                            <button className={"btn text-sm " + ("btn-primary" if active_tab == "courses" else "btn-ghost")} onClick={set_courses}>
                                📚 Courses
                            </button>
                            <button className={"btn text-sm " + ("btn-primary" if active_tab == "projects" else "btn-ghost")} onClick={set_projects}>
                                🛠 Projects
                            </button>
                            <button className={"btn text-sm " + ("btn-primary" if active_tab == "networking" else "btn-ghost")} onClick={set_networking}>
                                🤝 Networking
                            </button>
                        </div>

                        {active_tab == "internships" and (
                            <div className="flex flex-col gap-4">
                                {[
                                    <div key={str(i)} className="card p-5">
                                        <div className="flex items-start gap-4">
                                            <div className="w-12 h-12 rounded-xl flex items-center justify-center text-lg" style={{"background": "rgba(59,130,246,0.1)", "border": "1px solid rgba(59,130,246,0.2)"}}>
                                                🏢
                                            </div>
                                            <div className="flex-1">
                                                <div className="text-sm font-semibold text-foreground mb-1">
                                                    {str(opportunities.internships[i]).split(" — ")[0] if " — " in str(opportunities.internships[i]) else str(opportunities.internships[i])}
                                                </div>
                                                {" — " in str(opportunities.internships[i]) and (
                                                    <div className="text-xs text-muted-foreground mb-2 truncate">{str(opportunities.internships[i]).split(" — ")[1]}</div>
                                                )}
                                                <div className="flex gap-2 mt-1">
                                                    <span className="badge-blue text-xs">🌐 Web Result</span>
                                                    <span className="badge-green text-xs">Live</span>
                                                </div>
                                            </div>
                                            <button className="btn btn-primary text-xs py-1.5 px-3">Apply →</button>
                                        </div>
                                    </div>
                                    for i in range(len(opportunities.internships))
                                ]}
                            </div>
                        )}

                        {active_tab == "courses" and (
                            <div className="grid grid-cols-2 gap-4">
                                {[
                                    <div key={str(i)} className="card p-5">
                                        <div className="text-2xl mb-3">📚</div>
                                        <div className="text-sm font-semibold text-foreground mb-1">
                                            {str(opportunities.courses[i]).split(" — ")[0] if " — " in str(opportunities.courses[i]) else str(opportunities.courses[i])}
                                        </div>
                                        {" — " in str(opportunities.courses[i]) and (
                                            <div className="text-xs text-muted-foreground mb-2 truncate">{str(opportunities.courses[i]).split(" — ")[1]}</div>
                                        )}
                                        <div className="flex items-center justify-between mt-2">
                                            <span className="badge-purple text-xs">🌐 Web Result</span>
                                            <button className="btn btn-ghost text-xs py-1 px-2">Start →</button>
                                        </div>
                                    </div>
                                    for i in range(len(opportunities.courses))
                                ]}
                            </div>
                        )}

                        {active_tab == "projects" and (
                            <div className="grid grid-cols-2 gap-4">
                                {[
                                    <div key={str(i)} className="card p-5">
                                        <div className="text-2xl mb-3">🛠</div>
                                        <div className="text-sm font-semibold text-foreground mb-2">{str(opportunities.projects[i])}</div>
                                        <div className="flex items-center justify-between mt-3">
                                            <span className="badge-cyan text-xs">Project Idea</span>
                                            <button className="btn btn-ghost text-xs py-1 px-2">Build →</button>
                                        </div>
                                    </div>
                                    for i in range(len(opportunities.projects))
                                ]}
                            </div>
                        )}

                        {active_tab == "networking" and (
                            <div className="grid grid-cols-2 gap-4">
                                {[
                                    <div key={str(i)} className="card p-5">
                                        <div className="text-2xl mb-3">🤝</div>
                                        <div className="text-sm font-semibold text-foreground mb-2">{str(opportunities.networking[i])}</div>
                                        <span className="badge-yellow text-xs">Community</span>
                                    </div>
                                    for i in range(len(opportunities.networking))
                                ]}
                            </div>
                        )}
                    </div>
                )}
            </div>
        </div>
    );
}
