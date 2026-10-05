def:pub AnalyticsModule() -> JsxElement {
    has period: str = "month";

    def set_week(e: MouseEvent) -> None { period = "week"; }
    def set_month(e: MouseEvent) -> None { period = "month"; }
    def set_quarter(e: MouseEvent) -> None { period = "quarter"; }
    def set_year(e: MouseEvent) -> None { period = "year"; }

    bar_heights_week = [45, 62, 38, 71, 55, 28, 80];
    bar_heights_month = [55, 70, 48, 82, 65, 40, 75, 60, 85, 50, 72, 68];
    bar_heights_quarter = [65, 72, 58, 80];
    bar_heights_year = [55, 62, 70, 65, 75, 80, 72, 68, 85, 78, 82, 90];

    bars = bar_heights_week if period == "week" else (bar_heights_month if period == "month" else (bar_heights_quarter if period == "quarter" else bar_heights_year));
    labels_week = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    labels_month = ["1","4","7","10","13","16","19","22","25","28","30","31"];
    labels_quarter = ["Jan", "Feb", "Mar", "Apr"];
    labels_year = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
    labels = labels_week if period == "week" else (labels_month if period == "month" else (labels_quarter if period == "quarter" else labels_year));

    kpis = [
        {"label": "Total Revenue", "value": "$2.84M", "change": "+14.2%", "up": True, "icon": "💰"},
        {"label": "Operating Cost", "value": "$1.21M", "change": "-3.8%", "up": True, "icon": "📉"},
        {"label": "Profit Margin", "value": "57.4%", "change": "+2.1%", "up": True, "icon": "📈"},
        {"label": "Deliveries", "value": "18,472", "change": "+22.7%", "up": True, "icon": "📦"},
        {"label": "Fuel Cost", "value": "$284K", "change": "-8.4%", "up": True, "icon": "⛽"},
        {"label": "Avg Trip Cost", "value": "$15.38", "change": "-1.2%", "up": True, "icon": "🚛"},
    ];

    top_routes = [
        {"route": "Warehouse A → Hub 3", "trips": 847, "revenue": "$124K", "efficiency": 94},
        {"route": "Port → Retail East", "trips": 623, "revenue": "$98K", "efficiency": 88},
        {"route": "Supplier B → Warehouse C", "trips": 512, "revenue": "$87K", "efficiency": 91},
        {"route": "Cold Storage → Supermarket", "trips": 489, "revenue": "$76K", "efficiency": 96},
        {"route": "Airport → Distribution", "trips": 341, "revenue": "$54K", "efficiency": 82},
    ];

    return (
        <div>
            <div className="module-header">
                <div className="flex items-center justify-between">
                    <div>
                        <h1 className="module-title">📊 Analytics & Reporting</h1>
                        <p className="module-subtitle">Business intelligence, KPIs, and performance reporting</p>
                    </div>
                    <div className="flex gap-2">
                        <button className="btn btn-ghost text-xs px-3">📥 Export PDF</button>
                        <button className="btn btn-ghost text-xs px-3">📊 Export CSV</button>
                    </div>
                </div>
            </div>

            <div className="grid grid-cols-3 gap-4 mb-6">
                {[
                    <div key={str(i)} className="stat-card">
                        <div className="flex items-center gap-2 mb-2">
                            <span className="text-xl">{kpis[i]["icon"]}</span>
                            <div className="stat-label mb-0">{kpis[i]["label"]}</div>
                        </div>
                        <div className="stat-value text-2xl">{kpis[i]["value"]}</div>
                        <div className={"stat-change " + ("up" if kpis[i]["up"] else "down")}>{kpis[i]["change"]} vs last period</div>
                    </div>
                    for i in range(len(kpis))
                ]}
            </div>

            <div className="grid grid-cols-3 gap-4 mb-6">
                <div className="col-span-2 card p-5">
                    <div className="flex items-center justify-between mb-4">
                        <div className="text-sm font-bold text-foreground">Revenue Trend</div>
                        <div className="flex gap-1 border border-border rounded-lg p-1">
                            <button className={"btn btn-ghost px-3 py-1 text-xs " + ("bg-muted" if period == "week" else "")} onClick={set_week}>Week</button>
                            <button className={"btn btn-ghost px-3 py-1 text-xs " + ("bg-muted" if period == "month" else "")} onClick={set_month}>Month</button>
                            <button className={"btn btn-ghost px-3 py-1 text-xs " + ("bg-muted" if period == "quarter" else "")} onClick={set_quarter}>Quarter</button>
                            <button className={"btn btn-ghost px-3 py-1 text-xs " + ("bg-muted" if period == "year" else "")} onClick={set_year}>Year</button>
                        </div>
                    </div>
                    <div className="flex items-end gap-2 h-40 mb-2">
                        {[
                            <div
                                key={str(i)}
                                className="flex-1 rounded-t-sm"
                                style={{"height": str(bars[i]) + "%", "background": "linear-gradient(180deg, #6366f1 0%, rgba(99,102,241,0.3) 100%)", "minWidth": "8px"}}
                            ></div>
                            for i in range(len(bars))
                        ]}
                    </div>
                    <div className="flex justify-between text-xs text-muted-foreground">
                        {[
                            <span key={str(i)}>{labels[i]}</span>
                            for i in range(len(labels))
                        ]}
                    </div>
                </div>

                <div className="card p-5">
                    <div className="text-sm font-bold text-foreground mb-4">Fleet Utilization</div>
                    <div className="flex flex-col gap-4">
                        <div>
                            <div className="flex justify-between text-xs mb-1">
                                <span className="text-muted-foreground">Active Vehicles</span>
                                <span className="text-foreground font-bold">78%</span>
                            </div>
                            <div className="progress-bar"><div className="progress-fill" style={{"width": "78%"}}></div></div>
                        </div>
                        <div>
                            <div className="flex justify-between text-xs mb-1">
                                <span className="text-muted-foreground">Driver Utilization</span>
                                <span className="text-foreground font-bold">84%</span>
                            </div>
                            <div className="progress-bar"><div className="progress-fill" style={{"width": "84%"}}></div></div>
                        </div>
                        <div>
                            <div className="flex justify-between text-xs mb-1">
                                <span className="text-muted-foreground">Route Efficiency</span>
                                <span className="text-foreground font-bold">91%</span>
                            </div>
                            <div className="progress-bar"><div className="progress-fill" style={{"width": "91%"}}></div></div>
                        </div>
                        <div>
                            <div className="flex justify-between text-xs mb-1">
                                <span className="text-muted-foreground">On-Time Delivery</span>
                                <span className="text-foreground font-bold">94%</span>
                            </div>
                            <div className="progress-bar"><div className="progress-fill" style={{"width": "94%"}}></div></div>
                        </div>
                        <div>
                            <div className="flex justify-between text-xs mb-1">
                                <span className="text-muted-foreground">Fuel Efficiency</span>
                                <span className="text-foreground font-bold">87%</span>
                            </div>
                            <div className="progress-bar"><div className="progress-fill" style={{"width": "87%"}}></div></div>
                        </div>
                    </div>
                </div>
            </div>

            <div className="card overflow-hidden">
                <div className="px-5 py-4 border-b border-border text-sm font-bold text-foreground">Top Performing Routes</div>
                <table className="data-table">
                    <thead>
                        <tr>
                            <th>Route</th>
                            <th>Total Trips</th>
                            <th>Revenue</th>
                            <th>Efficiency Score</th>
                        </tr>
                    </thead>
                    <tbody>
                        {[
                            <tr key={str(i)}>
                                <td className="font-medium">{top_routes[i]["route"]}</td>
                                <td className="font-mono">{str(top_routes[i]["trips"])}</td>
                                <td className="font-bold text-emerald-400">{top_routes[i]["revenue"]}</td>
                                <td>
                                    <div className="flex items-center gap-2">
                                        <div className="progress-bar w-24">
                                            <div className="progress-fill" style={{"width": str(top_routes[i]["efficiency"]) + "%"}}></div>
                                        </div>
                                        <span className="text-sm font-bold">{str(top_routes[i]["efficiency"])}%</span>
                                    </div>
                                </td>
                            </tr>
                            for i in range(len(top_routes))
                        ]}
                    </tbody>
                </table>
            </div>
        </div>
    );
}
