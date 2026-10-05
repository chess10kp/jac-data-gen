def:pub AIHubModule() -> JsxElement {
    has active_model: str = "predictive";
    has running: bool = False;
    has result_shown: bool = False;

    def set_predictive(e: MouseEvent) -> None {
        active_model = "predictive";
        result_shown = False;
    }

    def set_anomaly(e: MouseEvent) -> None {
        active_model = "anomaly";
        result_shown = False;
    }

    def set_nlp(e: MouseEvent) -> None {
        active_model = "nlp";
        result_shown = False;
    }

    def set_optimize(e: MouseEvent) -> None {
        active_model = "optimize";
        result_shown = False;
    }

    async def run_model(e: MouseEvent) -> None {
        running = True;
        result_shown = False;
        running = False;
        result_shown = True;
    }

    insights = [
        {"icon": "🔮", "title": "Predictive Maintenance", "desc": "ORB-2847 has 87% probability of brake wear within 14 days", "confidence": 87, "action": "Schedule inspection"},
        {"icon": "⚡", "title": "Fuel Optimization", "desc": "Route 7B can save 340L/week with speed profile adjustment", "confidence": 94, "action": "Apply optimization"},
        {"icon": "🎯", "title": "Driver Risk Score", "desc": "DRV-005 shows elevated risk pattern — 3 hard braking events today", "confidence": 91, "action": "Send coaching alert"},
        {"icon": "📈", "title": "Demand Forecast", "desc": "Thursday peak demand expected +34% — pre-position 8 vehicles", "confidence": 78, "action": "Pre-position fleet"},
    ];

    return (
        <div>
            <div className="module-header">
                <div className="flex items-center justify-between">
                    <div>
                        <h1 className="module-title">🧠 AI Intelligence Hub</h1>
                        <p className="module-subtitle">Machine learning models, predictive analytics, and intelligent recommendations</p>
                    </div>
                    <div className="flex items-center gap-2">
                        <div className="flex items-center gap-2 px-3 py-1.5 rounded-full text-xs font-semibold text-emerald-400" style={{"background": "rgba(16,185,129,0.1)", "border": "1px solid rgba(16,185,129,0.2)"}}>
                            <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse inline-block"></span>
                            AI Models Online
                        </div>
                    </div>
                </div>
            </div>

            <div className="stats-grid-4 mb-6">
                <div className="stat-card">
                    <div className="stat-label">Models Active</div>
                    <div className="stat-value text-primary">12</div>
                    <div className="stat-change up">↑ All systems nominal</div>
                </div>
                <div className="stat-card">
                    <div className="stat-label">Predictions Today</div>
                    <div className="stat-value">4,821</div>
                    <div className="stat-change up">↑ 18% vs yesterday</div>
                </div>
                <div className="stat-card">
                    <div className="stat-label">Accuracy Rate</div>
                    <div className="stat-value text-emerald-400">96.3%</div>
                    <div className="stat-change up">↑ 1.2% this week</div>
                </div>
                <div className="stat-card">
                    <div className="stat-label">Cost Savings</div>
                    <div className="stat-value text-emerald-400">$48K</div>
                    <div className="stat-change up">↑ This month</div>
                </div>
            </div>

            <div className="grid grid-cols-3 gap-4 mb-6">
                <div className="col-span-2">
                    <div className="card p-5 mb-4">
                        <div className="text-sm font-bold text-foreground mb-4">🤖 AI Model Console</div>
                        <div className="flex gap-2 mb-4">
                            <button className={"btn text-xs px-3 py-2 " + ("btn-primary" if active_model == "predictive" else "btn-ghost")} onClick={set_predictive}>Predictive Maintenance</button>
                            <button className={"btn text-xs px-3 py-2 " + ("btn-primary" if active_model == "anomaly" else "btn-ghost")} onClick={set_anomaly}>Anomaly Detection</button>
                            <button className={"btn text-xs px-3 py-2 " + ("btn-primary" if active_model == "nlp" else "btn-ghost")} onClick={set_nlp}>NLP Analysis</button>
                            <button className={"btn text-xs px-3 py-2 " + ("btn-primary" if active_model == "optimize" else "btn-ghost")} onClick={set_optimize}>Route Optimizer</button>
                        </div>

                        <div className="bg-muted rounded-lg p-4 font-mono text-xs text-emerald-400 min-h-[120px] mb-4">
                            {active_model == "predictive" and (
                                <div>
                                    <div className="text-muted-foreground mb-2"># Predictive Maintenance Model v3.2</div>
                                    <div>{">"} Loading vehicle telemetry data... ✓</div>
                                    <div>{">"} Analyzing 847 sensor readings... ✓</div>
                                    <div>{">"} Running LSTM neural network...</div>
                                    {result_shown and <div className="text-primary mt-2">{">"} RESULT: 3 vehicles flagged for maintenance</div>}
                                </div>
                            )}
                            {active_model == "anomaly" and (
                                <div>
                                    <div className="text-muted-foreground mb-2"># Anomaly Detection Model v2.8</div>
                                    <div>{">"} Scanning driver behavior patterns... ✓</div>
                                    <div>{">"} Checking route deviations... ✓</div>
                                    <div>{">"} Running isolation forest algorithm...</div>
                                    {result_shown and <div className="text-primary mt-2">{">"} RESULT: 2 anomalies detected in last 24h</div>}
                                </div>
                            )}
                            {active_model == "nlp" and (
                                <div>
                                    <div className="text-muted-foreground mb-2"># NLP Sentiment Analysis v1.5</div>
                                    <div>{">"} Processing driver survey responses... ✓</div>
                                    <div>{">"} Extracting key themes... ✓</div>
                                    <div>{">"} Running BERT classification...</div>
                                    {result_shown and <div className="text-primary mt-2">{">"} RESULT: 78% positive sentiment, 3 action items</div>}
                                </div>
                            )}
                            {active_model == "optimize" and (
                                <div>
                                    <div className="text-muted-foreground mb-2"># Route Optimization Model v4.1</div>
                                    <div>{">"} Loading traffic data feeds... ✓</div>
                                    <div>{">"} Computing optimal paths... ✓</div>
                                    <div>{">"} Running genetic algorithm...</div>
                                    {result_shown and <div className="text-primary mt-2">{">"} RESULT: 12 routes optimized, 340L fuel saved</div>}
                                </div>
                            )}
                        </div>

                        <button className="btn btn-primary w-full" onClick={run_model}>
                            {"⏳ Running..." if running else "▶ Run Model"}
                        </button>
                    </div>
                </div>

                <div className="card p-5">
                    <div className="text-sm font-bold text-foreground mb-4">📊 Model Performance</div>
                    <div className="flex flex-col gap-4">
                        <div>
                            <div className="flex justify-between text-xs mb-1">
                                <span className="text-muted-foreground">Predictive Maint.</span>
                                <span className="text-foreground font-bold">94%</span>
                            </div>
                            <div className="progress-bar"><div className="progress-fill" style={{"width": "94%"}}></div></div>
                        </div>
                        <div>
                            <div className="flex justify-between text-xs mb-1">
                                <span className="text-muted-foreground">Anomaly Detection</span>
                                <span className="text-foreground font-bold">97%</span>
                            </div>
                            <div className="progress-bar"><div className="progress-fill" style={{"width": "97%"}}></div></div>
                        </div>
                        <div>
                            <div className="flex justify-between text-xs mb-1">
                                <span className="text-muted-foreground">Route Optimizer</span>
                                <span className="text-foreground font-bold">91%</span>
                            </div>
                            <div className="progress-bar"><div className="progress-fill" style={{"width": "91%"}}></div></div>
                        </div>
                        <div>
                            <div className="flex justify-between text-xs mb-1">
                                <span className="text-muted-foreground">NLP Analysis</span>
                                <span className="text-foreground font-bold">88%</span>
                            </div>
                            <div className="progress-bar"><div className="progress-fill" style={{"width": "88%"}}></div></div>
                        </div>
                    </div>
                </div>
            </div>

            <div className="text-sm font-bold text-foreground mb-3">💡 AI Insights & Recommendations</div>
            <div className="grid grid-cols-2 gap-4">
                {[
                    <div key={str(i)} className="card p-5">
                        <div className="flex items-start gap-3 mb-3">
                            <div className="text-2xl">{insights[i]["icon"]}</div>
                            <div>
                                <div className="text-sm font-bold text-foreground">{insights[i]["title"]}</div>
                                <div className="text-xs text-muted-foreground mt-1">{insights[i]["desc"]}</div>
                            </div>
                        </div>
                        <div className="flex items-center justify-between">
                            <div className="flex items-center gap-2">
                                <div className="progress-bar w-20">
                                    <div className="progress-fill" style={{"width": str(insights[i]["confidence"]) + "%"}}></div>
                                </div>
                                <span className="text-xs text-muted-foreground">{str(insights[i]["confidence"])}% confidence</span>
                            </div>
                            <button className="btn btn-secondary px-3 py-1.5 text-xs">{insights[i]["action"]}</button>
                        </div>
                    </div>
                    for i in range(len(insights))
                ]}
            </div>
        </div>
    );
}
