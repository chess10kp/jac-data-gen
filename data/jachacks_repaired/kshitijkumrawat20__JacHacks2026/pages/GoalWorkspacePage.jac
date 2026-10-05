import from "@jac/runtime" { useNavigate, jacIsLoggedIn, Navigate }
import from ..components.Sidebar { Sidebar }
import from ..services.appService { Goal, Mission, get_goals, add_goal, delete_goal, update_goal_progress, get_missions, add_mission, delete_mission, agent_generate_missions, agent_get_strategy, StrategyReport }

def:pub page() -> JsxElement {
    has goals: list[Goal] = [];
    has missions: list[Mission] = [];
    has selected_idx: int = 0;
    has loading: bool = True;
    has show_add_goal: bool = False;
    has show_add_mission: bool = False;
    has new_goal_title: str = "";
    has new_goal_desc: str = "";
    has new_goal_timeline: str = "3 months";
    has new_mission_title: str = "";
    has new_mission_tag: str = "General";
    has new_mission_diff: str = "Medium";
    has new_mission_xp: str = "100";
    has saving: bool = False;
    has ai_generating: bool = False;
    has ai_status: str = "";
    has strategy: StrategyReport | None = None;
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
            } except Exception as ex {
                error = "Failed to load data";
            }
            loading = False;
        }
    }

    async def do_open_add_goal() -> None {
        goals = await get_goals();
        missions = await get_missions();
        show_add_goal = True;
        show_add_mission = False;
        error = "";
    }

    async def do_close_add_goal() -> None {
        goals = await get_goals();
        show_add_goal = False;
        error = "";
    }

    async def do_open_add_mission() -> None {
        missions = await get_missions();
        show_add_mission = True;
        show_add_goal = False;
        error = "";
    }

    async def do_close_add_mission() -> None {
        missions = await get_missions();
        show_add_mission = False;
        error = "";
    }

    def open_add_goal(e: MouseEvent) -> None {
        do_open_add_goal();
    }

    def close_add_goal(e: MouseEvent) -> None {
        do_close_add_goal();
    }

    def open_add_mission(e: MouseEvent) -> None {
        do_open_add_mission();
    }

    def close_add_mission(e: MouseEvent) -> None {
        do_close_add_mission();
    }

    def handle_goal_title(e: ChangeEvent) -> None {
        new_goal_title = e.target.value;
    }

    def handle_goal_desc(e: ChangeEvent) -> None {
        new_goal_desc = e.target.value;
    }

    def handle_goal_timeline(e: ChangeEvent) -> None {
        new_goal_timeline = e.target.value;
    }

    def handle_mission_title(e: ChangeEvent) -> None {
        new_mission_title = e.target.value;
    }

    def handle_mission_tag(e: ChangeEvent) -> None {
        new_mission_tag = e.target.value;
    }

    def handle_mission_diff(e: ChangeEvent) -> None {
        new_mission_diff = e.target.value;
    }

    def handle_mission_xp(e: ChangeEvent) -> None {
        new_mission_xp = e.target.value;
    }

    async def submit_add_goal(e: FormEvent) -> None {
        e.preventDefault();
        if not new_goal_title { return; }
        saving = True;
        ai_generating = False;
        error = "";
        try {
            title: str = new_goal_title;
            description: str = new_goal_desc;
            timeline: str = new_goal_timeline;
            g = await add_goal(title, description, timeline);
            new_goals_list: list[Goal] = goals + [g];
            new_idx: int = len(new_goals_list) - 1;
            goals = new_goals_list;
            selected_idx = new_idx;
            new_goal_title = "";
            new_goal_desc = "";
            show_add_goal = False;
            saving = False;
            ai_generating = True;
            ai_status = "🤖 Planner Agent is generating your missions...";
            goal_id_for_ai: str = jid(g);
            goal_title_for_ai: str = title;
            goal_desc_for_ai: str = description;
            goal_timeline_for_ai: str = timeline;
            ai_missions = await agent_generate_missions(goal_id_for_ai, goal_title_for_ai, goal_desc_for_ai, goal_timeline_for_ai);
            missions = missions + ai_missions;
            ai_status = "✅ AI generated " + str(len(ai_missions)) + " missions for your goal!";
            ai_generating = False;
            strat = await agent_get_strategy(goal_id_for_ai);
            strategy = strat;
        } except Exception as ex {
            error = "Error: " + str(ex);
            ai_generating = False;
            saving = False;
        }
        saving = False;
    }

    async def submit_add_mission(e: FormEvent) -> None {
        e.preventDefault();
        saving = True;
        error = "";
        gid: str = "";
        if len(goals) > 0 and selected_idx < len(goals) {
            gid = jid(goals[selected_idx]);
        }
        title: str = new_mission_title;
        difficulty: str = new_mission_diff;
        tag: str = new_mission_tag;
        goal_id: str = gid;
        try {
            m = await add_mission(title, difficulty, 100, tag, goal_id);
            missions = missions + [m];
            new_mission_title = "";
            show_add_mission = False;
        } except Exception as ex {
            error = "Error: " + str(ex);
        }
        saving = False;
    }

    async def do_delete_goal(gid: str) -> None {
        goal_id: str = gid;
        ok = await delete_goal(goal_id);
        if ok {
            new_goals: list[Goal] = [];
            for g in goals {
                if jid(g) != gid {
                    new_goals = new_goals + [g];
                }
            }
            goals = new_goals;
            selected_idx = 0;
        }
    }

    async def do_delete_mission(mid: str) -> None {
        mission_id: str = mid;
        ok = await delete_mission(mission_id);
        if ok {
            new_missions: list[Mission] = [];
            for m in missions {
                if jid(m) != mid {
                    new_missions = new_missions + [m];
                }
            }
            missions = new_missions;
        }
    }

    async def do_update_progress(gid: str, val: int) -> None {
        goal_id: str = gid;
        progress: int = val;
        result = await update_goal_progress(goal_id, progress);
        if result is not None {
            new_goals: list[Goal] = [];
            for g in goals {
                if jid(g) == gid {
                    new_goals = new_goals + [result];
                } else {
                    new_goals = new_goals + [g];
                }
            }
            goals = new_goals;
        }
    }

    def make_select_goal(idx: int) -> Any {
        async def do_select(e: Any) -> None {
            goals = await get_goals();
            selected_idx = idx;
        }
        return do_select;
    }

    def make_ai_generate(gid: str, gtitle: str, gdesc: str, gtimeline: str) -> Any {
        async def do_generate(e: Any) -> None {
            ai_generating = True;
            ai_status = "🤖 Planner Agent generating missions...";
            try {
                goal_id: str = gid;
                goal_title: str = gtitle;
                goal_description: str = gdesc;
                goal_timeline: str = gtimeline;
                new_missions = await agent_generate_missions(goal_id, goal_title, goal_description, goal_timeline);
                missions = missions + new_missions;
                ai_status = "✅ Generated " + str(len(new_missions)) + " AI missions!";
                strat = await agent_get_strategy(goal_id);
                strategy = strat;
            } except Exception as ex {
                ai_status = "❌ AI generation failed: " + str(ex);
            }
            ai_generating = False;
        }
        return do_generate;
    }

    def make_delete_goal(gid: str) -> Any {
        def do_del(e: MouseEvent) -> None {
            do_delete_goal(gid);
        }
        return do_del;
    }

    def make_delete_mission(mid: str) -> Any {
        def do_del(e: MouseEvent) -> None {
            do_delete_mission(mid);
        }
        return do_del;
    }

    def make_set_progress(gid: str, val: int) -> Any {
        def do_prog(e: MouseEvent) -> None {
            do_update_progress(gid, val);
        }
        return do_prog;
    }

    return (
        <div className="page">
            <Sidebar />
            <div className="page-content">
                <div className="page-header">
                    <div>
                        <h1 className="text-2xl font-bold text-foreground">Goal Workspace</h1>
                        <p className="text-muted-foreground text-sm mt-1">Create goals, add missions, track progress</p>
                    </div>
                    <button className="btn btn-primary" onClick={open_add_goal}>+ Add Goal</button>
                </div>

                {error and <div className="error-box mb-4">{error}</div>}

                {loading and (
                    <div className="flex items-center justify-center py-20">
                        <div className="text-center">
                            <div className="flex gap-2 justify-center mb-3">
                                <span className="typing-dot"></span>
                                <span className="typing-dot"></span>
                                <span className="typing-dot"></span>
                            </div>
                            <p className="text-muted-foreground text-sm">Loading your goals...</p>
                        </div>
                    </div>
                )}

                {not loading and show_add_goal and (
                    <div className="card p-6 mb-6" style={{"border": "1px solid rgba(59,130,246,0.3)"}}>
                        <h2 className="text-base font-semibold text-foreground mb-4">New Goal</h2>
                        <form onSubmit={submit_add_goal}>
                            <div className="mb-4">
                                <label className="label">Goal Title *</label>
                                <input className="input" type="text" value={new_goal_title} onChange={handle_goal_title} placeholder="e.g. Become an AI Engineer in 6 months" required={True} />
                            </div>
                            <div className="mb-4">
                                <label className="label">Description</label>
                                <input className="input" type="text" value={new_goal_desc} onChange={handle_goal_desc} placeholder="What does success look like?" />
                            </div>
                            <div className="mb-4">
                                <label className="label">Timeline</label>
                                <input className="input" type="text" value={new_goal_timeline} onChange={handle_goal_timeline} placeholder="e.g. 6 months" />
                            </div>
                            <div className="flex gap-3">
                                <button type="submit" className="btn btn-primary" disabled={saving}>
                                    {saving and "Creating..." or "Create Goal"}
                                </button>
                                <button type="button" className="btn btn-ghost" onClick={close_add_goal}>Cancel</button>
                            </div>
                        </form>
                    </div>
                )}

                {not loading and len(goals) == 0 and not show_add_goal and (
                    <div className="card p-12 text-center">
                        <div className="text-5xl mb-4">🎯</div>
                        <h2 className="text-xl font-semibold text-foreground mb-2">No goals yet</h2>
                        <p className="text-muted-foreground text-sm mb-6">Add your first long-term goal and let AI agents build your roadmap.</p>
                        <button className="btn btn-primary" onClick={open_add_goal}>+ Add Your First Goal</button>
                    </div>
                )}

                {not loading and len(goals) > 0 and (
                    <div>
                        <div className="flex gap-3 mb-6 flex-wrap">
                            {[
                                <button
                                    key={jid(goals[i])}
                                    className={"px-4 py-2 rounded-xl text-sm font-medium transition-all " + ("text-white" if selected_idx == i else "text-muted-foreground")}
                                    style={{"background": "rgba(59,130,246,0.2)" if selected_idx == i else "rgba(255,255,255,0.03)", "border": "1px solid " + ("rgba(59,130,246,0.4)" if selected_idx == i else "rgba(255,255,255,0.06)")}}
                                    onClick={make_select_goal(i)}
                                >
                                    {goals[i].title}
                                </button>
                                for i in range(len(goals))
                            ]}
                        </div>

                        {selected_idx < len(goals) and (
                            <div className="grid grid-cols-3 gap-6">
                                <div className="col-span-2">
                                    <div className="card p-6 mb-6">
                                        <div className="flex items-start justify-between mb-4">
                                            <div>
                                                <h2 className="text-lg font-semibold text-foreground">{goals[selected_idx].title}</h2>
                                                <span className="badge-blue mt-1">{goals[selected_idx].timeline}</span>
                                                {goals[selected_idx].description and (
                                                    <p className="text-sm text-muted-foreground mt-2">{goals[selected_idx].description}</p>
                                                )}
                                            </div>
                                            <button className="btn btn-ghost text-xs" style={{"color": "#ef4444"}} onClick={make_delete_goal(jid(goals[selected_idx]))}>Delete</button>
                                        </div>

                                        <div className="mb-6">
                                            <div className="flex items-center justify-between mb-1">
                                                <span className="text-xs text-muted-foreground">Progress</span>
                                                <span className="text-sm font-bold text-foreground">{str(goals[selected_idx].progress) + "%"}</span>
                                            </div>
                                            <div className="progress-bar mb-2">
                                                <div className="progress-fill" style={{"width": str(goals[selected_idx].progress) + "%"}}></div>
                                            </div>
                                            <div className="flex gap-2">
                                                {[
                                                    <button key={str(v)} className="btn btn-ghost text-xs py-1 px-2" onClick={make_set_progress(jid(goals[selected_idx]), v)}>
                                                        {str(v) + "%"}
                                                    </button>
                                                    for v in [10, 25, 50, 75, 100]
                                                ]}
                                            </div>
                                        </div>

                                        <div className="flex items-center justify-between mb-3">
                                            <h3 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider">Missions</h3>
                                            <div className="flex gap-2">
                                                <button className="btn btn-accent text-xs py-1.5 px-3" onClick={make_ai_generate(jid(goals[selected_idx]), goals[selected_idx].title, goals[selected_idx].description, goals[selected_idx].timeline)}>
                                                    🤖 AI Generate
                                                </button>
                                                <button className="btn btn-ghost text-xs" onClick={open_add_mission}>+ Manual</button>
                                            </div>
                                        </div>

                                        {ai_generating and (
                                            <div className="flex items-center gap-3 p-3 rounded-xl mb-3" style={{"background": "rgba(139,92,246,0.05)", "border": "1px solid rgba(139,92,246,0.2)"}}>
                                                <div className="flex gap-1">
                                                    <span className="typing-dot"></span>
                                                    <span className="typing-dot"></span>
                                                    <span className="typing-dot"></span>
                                                </div>
                                                <p className="text-xs text-muted-foreground">{ai_status}</p>
                                            </div>
                                        )}

                                        {show_add_mission and (
                                            <div className="p-4 rounded-xl mb-4" style={{"background": "rgba(59,130,246,0.05)", "border": "1px solid rgba(59,130,246,0.15)"}}>
                                                <form onSubmit={submit_add_mission}>
                                                    <div className="mb-3">
                                                        <label className="label">Mission Title</label>
                                                        <input className="input" type="text" value={new_mission_title} onChange={handle_mission_title} placeholder="e.g. Solve 3 LeetCode problems" />
                                                    </div>
                                                    <div className="grid grid-cols-3 gap-3 mb-3">
                                                        <div>
                                                            <label className="label">Tag</label>
                                                            <input className="input" type="text" value={new_mission_tag} onChange={handle_mission_tag} placeholder="DSA" />
                                                        </div>
                                                        <div>
                                                            <label className="label">Difficulty</label>
                                                            <input className="input" type="text" value={new_mission_diff} onChange={handle_mission_diff} placeholder="Medium" />
                                                        </div>
                                                        <div>
                                                            <label className="label">XP</label>
                                                            <input className="input" type="number" value={new_mission_xp} onChange={handle_mission_xp} placeholder="100" />
                                                        </div>
                                                    </div>
                                                    <div className="flex gap-2">
                                                        <button type="submit" className="btn btn-primary text-xs" disabled={saving}>
                                                            {saving and "Adding..." or "Add Mission"}
                                                        </button>
                                                        <button type="button" className="btn btn-ghost text-xs" onClick={close_add_mission}>Cancel</button>
                                                    </div>
                                                </form>
                                            </div>
                                        )}

                                        <div className="flex flex-col gap-2">
                                            {[
                                                <div key={jid(missions[i])} className="flex items-center gap-3 p-3 rounded-xl" style={{"background": "rgba(59,130,246,0.03)", "border": "1px solid rgba(59,130,246,0.08)"}}>
                                                    <div className="flex-1 min-w-0">
                                                        <div className="text-sm font-medium text-foreground">{missions[i].title}</div>
                                                        <div className="flex gap-2 mt-1">
                                                            <span className="badge-blue text-xs">{missions[i].tag}</span>
                                                            <span className="text-xs text-muted-foreground">{missions[i].difficulty}</span>
                                                            <span className="text-xs" style={{"color": "#f59e0b"}}>+{str(missions[i].xp)} XP</span>
                                                        </div>
                                                    </div>
                                                    <button className="btn btn-ghost text-xs py-1 px-2" style={{"color": "#ef4444"}} onClick={make_delete_mission(jid(missions[i]))}>✕</button>
                                                </div>
                                                for i in range(len(missions))
                                                if missions[i].goal_id == jid(goals[selected_idx])
                                            ]}
                                        </div>

                                        {len([m for m in missions if m.goal_id == jid(goals[selected_idx])]) == 0 and not show_add_mission and (
                                            <div className="text-center py-4">
                                                <p className="text-muted-foreground text-sm">No missions for this goal yet.</p>
                                                <button className="btn btn-ghost text-xs mt-2" onClick={open_add_mission}>+ Add first mission</button>
                                            </div>
                                        )}
                                    </div>
                                </div>

                                <div>
                                    <div className="card p-5 mb-4">
                                        <h2 className="text-base font-semibold text-foreground mb-4">All Goals</h2>
                                        <div className="flex flex-col gap-3">
                                            {[
                                                <div
                                                    key={jid(goals[i])}
                                                    className="p-3 rounded-xl cursor-pointer"
                                                    style={{"background": "rgba(59,130,246,0.08)" if selected_idx == i else "rgba(59,130,246,0.03)", "border": "1px solid " + ("rgba(59,130,246,0.2)" if selected_idx == i else "rgba(59,130,246,0.06)")}}
                                                    onClick={make_select_goal(i)}
                                                >
                                                    <div className="text-sm font-medium text-foreground mb-1">{goals[i].title}</div>
                                                    <div className="flex items-center gap-2">
                                                        <div className="progress-bar flex-1">
                                                            <div className="progress-fill" style={{"width": str(goals[i].progress) + "%"}}></div>
                                                        </div>
                                                        <span className="text-xs text-muted-foreground">{str(goals[i].progress) + "%"}</span>
                                                    </div>
                                                </div>
                                                for i in range(len(goals))
                                            ]}
                                        </div>
                                        <button className="btn btn-ghost w-full mt-4 text-xs" onClick={open_add_goal}>+ Add Goal</button>
                                    </div>

                                    {ai_generating and (
                                        <div className="card p-4 mb-4" style={{"border": "1px solid rgba(139,92,246,0.3)"}}>
                                            <div className="flex items-center gap-3">
                                                <div className="flex gap-1">
                                                    <span className="typing-dot"></span>
                                                    <span className="typing-dot"></span>
                                                    <span className="typing-dot"></span>
                                                </div>
                                                <p className="text-xs text-muted-foreground">{ai_status}</p>
                                            </div>
                                        </div>
                                    )}

                                    {ai_status and not ai_generating and (
                                        <div className="card p-4 mb-4" style={{"border": "1px solid rgba(16,185,129,0.3)", "background": "rgba(16,185,129,0.05)"}}>
                                            <p className="text-xs text-green-400">{ai_status}</p>
                                        </div>
                                    )}

                                    {strategy is not None and (
                                        <div className="card p-5">
                                            <div className="flex items-center gap-2 mb-3">
                                                <span style={{"fontSize": "14px"}}>🤖</span>
                                                <h2 className="text-sm font-semibold text-foreground">AI Strategy</h2>
                                                <span className="badge-purple text-xs">Planner Agent</span>
                                            </div>
                                            <div className="mb-3">
                                                <div className="text-xs text-muted-foreground uppercase tracking-wider mb-1">This Week</div>
                                                <p className="text-xs text-foreground leading-relaxed">{strategy.weekly_focus}</p>
                                            </div>
                                            <div className="mb-3">
                                                <div className="text-xs text-muted-foreground uppercase tracking-wider mb-1">Milestones</div>
                                                <div className="flex flex-col gap-1">
                                                    {[
                                                        <div key={str(i)} className="flex items-start gap-2">
                                                            <span className="text-xs" style={{"color": "#3b82f6"}}>→</span>
                                                            <span className="text-xs text-muted-foreground">{str(strategy.milestones[i])}</span>
                                                        </div>
                                                        for i in range(len(strategy.milestones))
                                                    ]}
                                                </div>
                                            </div>
                                            <div>
                                                <div className="text-xs text-muted-foreground uppercase tracking-wider mb-1">Resources</div>
                                                <div className="flex flex-col gap-1">
                                                    {[
                                                        <div key={str(i)} className="text-xs text-muted-foreground">📚 {str(strategy.key_resources[i])}</div>
                                                        for i in range(len(strategy.key_resources))
                                                    ]}
                                                </div>
                                            </div>
                                        </div>
                                    )}
                                </div>
                            </div>
                        )}
                    </div>
                )}
            </div>
        </div>
    );
}
