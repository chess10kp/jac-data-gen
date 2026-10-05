def:pub SurveyModule() -> JsxElement {
    has active_tab: str = "surveys";
    has survey_submitted: bool = False;
    has rating: int = 0;
    has feedback: str = "";
    has selected_driver: str = "DRV-001";

    def set_surveys(e: MouseEvent) -> None { active_tab = "surveys"; }
    def set_rewards(e: MouseEvent) -> None { active_tab = "rewards"; }
    def set_leaderboard(e: MouseEvent) -> None { active_tab = "leaderboard"; }

    def set_rating_1(e: MouseEvent) -> None { rating = 1; }
    def set_rating_2(e: MouseEvent) -> None { rating = 2; }
    def set_rating_3(e: MouseEvent) -> None { rating = 3; }
    def set_rating_4(e: MouseEvent) -> None { rating = 4; }
    def set_rating_5(e: MouseEvent) -> None { rating = 5; }

    rating_handlers = [set_rating_1, set_rating_2, set_rating_3, set_rating_4, set_rating_5];

    def handle_feedback(e: ChangeEvent) -> None {
        feedback = e.target.value;
    }

    def submit_survey(e: MouseEvent) -> None {
        survey_submitted = True;
    }

    def reset_survey(e: MouseEvent) -> None {
        survey_submitted = False;
        rating = 0;
        feedback = "";
    }

    leaderboard = [
        {"rank": 1, "name": "Aisha Patel", "id": "DRV-004", "points": 9840, "score": 97, "badge": "🏆 Elite Driver"},
        {"rank": 2, "name": "Marcus Chen", "id": "DRV-001", "points": 8720, "score": 94, "badge": "🥈 Pro Driver"},
        {"rank": 3, "name": "James Rodriguez", "id": "DRV-003", "points": 8340, "score": 91, "badge": "🥉 Senior Driver"},
        {"rank": 4, "name": "Priya Sharma", "id": "DRV-008", "points": 7980, "score": 93, "badge": "⭐ Star Driver"},
        {"rank": 5, "name": "Elena Vasquez", "id": "DRV-006", "points": 7210, "score": 85, "badge": "✅ Certified"},
        {"rank": 6, "name": "Sarah Williams", "id": "DRV-002", "points": 6890, "score": 88, "badge": "✅ Certified"},
    ];

    rewards = [
        {"icon": "🎁", "name": "Fuel Card Top-up", "points": 500, "desc": "Add $50 to your fuel card", "available": True},
        {"icon": "🏖️", "name": "Extra Day Off", "points": 2000, "desc": "Redeem for a paid day off", "available": True},
        {"icon": "🎓", "name": "Training Course", "points": 1000, "desc": "Access premium safety training", "available": True},
        {"icon": "🎮", "name": "Electronics Voucher", "points": 3000, "desc": "$200 electronics store voucher", "available": False},
        {"icon": "✈️", "name": "Travel Voucher", "points": 5000, "desc": "$500 travel credit", "available": False},
        {"icon": "🏆", "name": "Driver of the Year", "points": 10000, "desc": "Annual award + $1000 bonus", "available": False},
    ];

    return (
        <div>
            <div className="module-header">
                <div className="flex items-center justify-between">
                    <div>
                        <h1 className="module-title">🏆 Driver Survey & Rewards</h1>
                        <p className="module-subtitle">Driver engagement, satisfaction surveys, and gamified reward programs</p>
                    </div>
                    <button className="btn btn-primary">+ Create Survey</button>
                </div>
            </div>

            <div className="stats-grid-4 mb-6">
                <div className="stat-card">
                    <div className="stat-label">Survey Response Rate</div>
                    <div className="stat-value text-primary">87%</div>
                    <div className="stat-change up">↑ 12% this quarter</div>
                </div>
                <div className="stat-card">
                    <div className="stat-label">Avg Satisfaction</div>
                    <div className="stat-value text-emerald-400">4.3/5</div>
                    <div className="stat-change up">↑ 0.4 pts improvement</div>
                </div>
                <div className="stat-card">
                    <div className="stat-label">Points Awarded</div>
                    <div className="stat-value">124K</div>
                    <div className="stat-change up">↑ This month</div>
                </div>
                <div className="stat-card">
                    <div className="stat-label">Rewards Redeemed</div>
                    <div className="stat-value text-amber-400">48</div>
                    <div className="stat-change">This month</div>
                </div>
            </div>

            <div className="flex gap-1 border border-border rounded-lg p-1 mb-5 w-fit">
                <button className={"btn btn-ghost px-4 py-2 text-sm " + ("bg-muted text-foreground" if active_tab == "surveys" else "")} onClick={set_surveys}>📋 Surveys</button>
                <button className={"btn btn-ghost px-4 py-2 text-sm " + ("bg-muted text-foreground" if active_tab == "rewards" else "")} onClick={set_rewards}>🎁 Rewards</button>
                <button className={"btn btn-ghost px-4 py-2 text-sm " + ("bg-muted text-foreground" if active_tab == "leaderboard" else "")} onClick={set_leaderboard}>🏆 Leaderboard</button>
            </div>

            {active_tab == "surveys" and (
                <div className="grid grid-cols-2 gap-4">
                    <div className="card p-6">
                        <div className="text-sm font-bold text-foreground mb-1">📋 Weekly Driver Check-in</div>
                        <div className="text-xs text-muted-foreground mb-5">Help us improve your experience</div>

                        {survey_submitted and (
                            <div className="text-center py-8">
                                <div className="text-5xl mb-4">🎉</div>
                                <div className="text-lg font-bold text-foreground mb-2">Thank you!</div>
                                <div className="text-sm text-muted-foreground mb-4">You earned <span className="text-primary font-bold">+150 points</span> for completing this survey.</div>
                                <button className="btn btn-ghost text-xs" onClick={reset_survey}>Submit another response</button>
                            </div>
                        )}

                        {not survey_submitted and (
                            <div className="flex flex-col gap-5">
                                <div>
                                    <label className="label">How was your shift today?</label>
                                    <div className="flex gap-2">
                                        {[
                                            <button
                                                key={str(i)}
                                                className={"text-2xl transition-transform " + ("scale-125" if rating == i + 1 else "opacity-50 hover:opacity-100")}
                                                onClick={rating_handlers[i]}
                                            >
                                                {"⭐"}
                                            </button>
                                            for i in range(5)
                                        ]}
                                        {rating > 0 and (
                                            <span className="text-sm text-muted-foreground ml-2 self-center">
                                                {str(rating)}/5
                                            </span>
                                        )}
                                    </div>
                                </div>
                                <div>
                                    <label className="label">Any feedback or concerns?</label>
                                    <textarea
                                        className="input min-h-[80px] resize-none"
                                        placeholder="Share your thoughts..."
                                        value={feedback}
                                        onChange={handle_feedback}
                                    ></textarea>
                                </div>
                                <div>
                                    <label className="label">Route Conditions</label>
                                    <div className="flex gap-2 flex-wrap">
                                        <button className="btn btn-ghost text-xs px-3 py-1.5">🟢 Good</button>
                                        <button className="btn btn-ghost text-xs px-3 py-1.5">🟡 Fair</button>
                                        <button className="btn btn-ghost text-xs px-3 py-1.5">🔴 Poor</button>
                                        <button className="btn btn-ghost text-xs px-3 py-1.5">🚧 Construction</button>
                                    </div>
                                </div>
                                <button className="btn btn-primary" onClick={submit_survey}>
                                    Submit Survey (+150 pts)
                                </button>
                            </div>
                        )}
                    </div>

                    <div className="flex flex-col gap-4">
                        <div className="card p-5">
                            <div className="text-sm font-bold text-foreground mb-3">📊 Recent Survey Results</div>
                            <div className="flex flex-col gap-3">
                                <div>
                                    <div className="flex justify-between text-xs mb-1">
                                        <span className="text-muted-foreground">Overall Satisfaction</span>
                                        <span className="text-foreground font-bold">86%</span>
                                    </div>
                                    <div className="progress-bar"><div className="progress-fill" style={{"width": "86%"}}></div></div>
                                </div>
                                <div>
                                    <div className="flex justify-between text-xs mb-1">
                                        <span className="text-muted-foreground">Route Quality</span>
                                        <span className="text-foreground font-bold">78%</span>
                                    </div>
                                    <div className="progress-bar"><div className="progress-fill" style={{"width": "78%"}}></div></div>
                                </div>
                                <div>
                                    <div className="flex justify-between text-xs mb-1">
                                        <span className="text-muted-foreground">Equipment Condition</span>
                                        <span className="text-foreground font-bold">91%</span>
                                    </div>
                                    <div className="progress-bar"><div className="progress-fill" style={{"width": "91%"}}></div></div>
                                </div>
                                <div>
                                    <div className="flex justify-between text-xs mb-1">
                                        <span className="text-muted-foreground">Management Support</span>
                                        <span className="text-foreground font-bold">82%</span>
                                    </div>
                                    <div className="progress-bar"><div className="progress-fill" style={{"width": "82%"}}></div></div>
                                </div>
                            </div>
                        </div>
                        <div className="card p-5">
                            <div className="text-sm font-bold text-foreground mb-3">💬 Recent Feedback</div>
                            <div className="flex flex-col gap-3">
                                <div className="p-3 rounded-lg bg-muted text-xs">
                                    <div className="text-foreground mb-1">"Route planning has improved significantly this month."</div>
                                    <div className="text-muted-foreground">— DRV-004 · ⭐⭐⭐⭐⭐</div>
                                </div>
                                <div className="p-3 rounded-lg bg-muted text-xs">
                                    <div className="text-foreground mb-1">"Need better rest stop information on long hauls."</div>
                                    <div className="text-muted-foreground">— DRV-002 · ⭐⭐⭐⭐</div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            )}

            {active_tab == "rewards" and (
                <div className="grid grid-cols-3 gap-4">
                    {[
                        <div key={str(i)} className={"card p-5 " + ("opacity-50" if not rewards[i]["available"] else "")}>
                            <div className="text-3xl mb-3">{rewards[i]["icon"]}</div>
                            <div className="text-sm font-bold text-foreground mb-1">{rewards[i]["name"]}</div>
                            <div className="text-xs text-muted-foreground mb-4">{rewards[i]["desc"]}</div>
                            <div className="flex items-center justify-between">
                                <span className="badge badge-primary">{str(rewards[i]["points"])} pts</span>
                                <button className={"btn text-xs px-3 py-1.5 " + ("btn-primary" if rewards[i]["available"] else "btn-ghost opacity-50 cursor-not-allowed")}>
                                    {"Redeem" if rewards[i]["available"] else "Locked"}
                                </button>
                            </div>
                        </div>
                        for i in range(len(rewards))
                    ]}
                </div>
            )}

            {active_tab == "leaderboard" and (
                <div className="card overflow-hidden">
                    <div className="px-5 py-4 border-b border-border text-sm font-bold text-foreground">🏆 Driver Leaderboard — December 2024</div>
                    <table className="data-table">
                        <thead>
                            <tr>
                                <th>Rank</th>
                                <th>Driver</th>
                                <th>Safety Score</th>
                                <th>Points</th>
                                <th>Badge</th>
                            </tr>
                        </thead>
                        <tbody>
                            {[
                                <tr key={str(i)} className={"" + ("bg-primary/5" if i < 3 else "")}>
                                    <td>
                                        <span className="text-xl">
                                            {"🥇" if leaderboard[i]["rank"] == 1 else ("🥈" if leaderboard[i]["rank"] == 2 else ("🥉" if leaderboard[i]["rank"] == 3 else str(leaderboard[i]["rank"])))}
                                        </span>
                                    </td>
                                    <td>
                                        <div className="flex items-center gap-2">
                                            <div className="w-8 h-8 rounded-full bg-primary/20 flex items-center justify-center text-primary font-bold text-xs">
                                                {str(leaderboard[i]["name"])[0]}
                                            </div>
                                            <div>
                                                <div className="text-sm font-bold text-foreground">{leaderboard[i]["name"]}</div>
                                                <div className="text-xs text-muted-foreground">{leaderboard[i]["id"]}</div>
                                            </div>
                                        </div>
                                    </td>
                                    <td>
                                        <div className="flex items-center gap-2">
                                            <div className="progress-bar w-16">
                                                <div className="progress-fill" style={{"width": str(leaderboard[i]["score"]) + "%"}}></div>
                                            </div>
                                            <span className="text-sm font-bold">{str(leaderboard[i]["score"])}</span>
                                        </div>
                                    </td>
                                    <td className="font-black text-primary font-mono">{str(leaderboard[i]["points"])}</td>
                                    <td><span className="badge badge-primary text-xs">{leaderboard[i]["badge"]}</span></td>
                                </tr>
                                for i in range(len(leaderboard))
                            ]}
                        </tbody>
                    </table>
                </div>
            )}
        </div>
    );
}
