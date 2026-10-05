def:pub OperationsModule() -> JsxElement {
    has active_tab: str = "dispatch";

    dispatches = [
        {"id": "DSP-4821", "origin": "Warehouse A", "dest": "Distribution Center 3", "driver": "Marcus Chen", "vehicle": "ORB-2847", "eta": "14:32", "status": "in-transit", "priority": "high"},
        {"id": "DSP-4820", "origin": "Port Terminal", "dest": "Retail Hub East", "driver": "Aisha Patel", "vehicle": "ORB-0892", "eta": "15:10", "status": "in-transit", "priority": "normal"},
        {"id": "DSP-4819", "origin": "Supplier Dock B", "dest": "Warehouse C", "driver": "Elena Vasquez", "vehicle": "ORB-2156", "eta": "16:45", "status": "in-transit", "priority": "low"},
        {"id": "DSP-4818", "origin": "Warehouse A", "dest": "Airport Cargo", "driver": "Sarah Williams", "vehicle": "ORB-1923", "eta": "13:55", "status": "delivered", "priority": "high"},
        {"id": "DSP-4817", "origin": "Cold Storage", "dest": "Supermarket Chain", "driver": "Priya Sharma", "vehicle": "ORB-5512", "eta": "17:20", "status": "pending", "priority": "normal"},
    ];

    def set_tab(tab: str) -> None {
        active_tab = tab;
    }

    def set_dispatch(e: MouseEvent) -> None {
        set_tab("dispatch");
    }

    def set_schedule(e: MouseEvent) -> None {
        set_tab("schedule");
    }

    def set_alerts(e: MouseEvent) -> None {
        set_tab("alerts");
    }

    def get_priority_badge(p: str) -> str {
        if p == "high" { return "badge-danger"; }
        if p == "low" { return "badge-info"; }
        return "badge-secondary";
    }

    def get_status_badge(s: str) -> str {
        if s == "delivered" { return "badge-success"; }
        if s == "in-transit" { return "badge-primary"; }
        return "badge-warning";
    }

    return (
        <div>
            <div className="module-header">
                <div className="flex items-center justify-between">
                    <div>
                        <h1 className="module-title">⚙️ Operations</h1>
                        <p className="module-subtitle">Dispatch management, scheduling, and operational alerts</p>
                    </div>
                    <button className="btn btn-primary">+ New Dispatch</button>
                </div>
            </div>

            <div className="stats-grid-4 mb-6">
                <div className="stat-card">
                    <div className="stat-label">Active Dispatches</div>
                    <div className="stat-value">24</div>
                    <div className="stat-change up">↑ 6 since morning</div>
                </div>
                <div className="stat-card">
                    <div className="stat-label">Delivered Today</div>
                    <div className="stat-value text-emerald-400">187</div>
                    <div className="stat-change up">↑ 12% vs yesterday</div>
                </div>
                <div className="stat-card">
                    <div className="stat-label">On-Time Rate</div>
                    <div className="stat-value text-primary">94.2%</div>
                    <div className="stat-change up">↑ 2.1% this week</div>
                </div>
                <div className="stat-card">
                    <div className="stat-label">Pending</div>
                    <div className="stat-value text-amber-400">8</div>
                    <div className="stat-change">Awaiting assignment</div>
                </div>
            </div>

            <div className="flex gap-1 border border-border rounded-lg p-1 mb-5 w-fit">
                <button className={"btn btn-ghost px-4 py-2 text-sm " + ("bg-muted text-foreground" if active_tab == "dispatch" else "")} onClick={set_dispatch}>📋 Dispatch Board</button>
                <button className={"btn btn-ghost px-4 py-2 text-sm " + ("bg-muted text-foreground" if active_tab == "schedule" else "")} onClick={set_schedule}>📅 Schedule</button>
                <button className={"btn btn-ghost px-4 py-2 text-sm " + ("bg-muted text-foreground" if active_tab == "alerts" else "")} onClick={set_alerts}>🔔 Alerts</button>
            </div>

            {active_tab == "dispatch" and (
                <div className="card overflow-hidden">
                    <div className="px-5 py-4 border-b border-border">
                        <div className="text-sm font-bold text-foreground">Active Dispatch Board</div>
                    </div>
                    <table className="data-table">
                        <thead>
                            <tr>
                                <th>Dispatch ID</th>
                                <th>Origin → Destination</th>
                                <th>Driver</th>
                                <th>Vehicle</th>
                                <th>ETA</th>
                                <th>Priority</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {[
                                <tr key={str(dispatches[i]["id"])}>
                                    <td className="font-mono text-xs text-primary">{dispatches[i]["id"]}</td>
                                    <td className="text-xs">
                                        <div className="font-medium text-foreground">{dispatches[i]["origin"]}</div>
                                        <div className="text-muted-foreground">→ {dispatches[i]["dest"]}</div>
                                    </td>
                                    <td className="text-sm">{dispatches[i]["driver"]}</td>
                                    <td className="font-mono text-xs">{dispatches[i]["vehicle"]}</td>
                                    <td className="font-mono text-sm font-bold">{dispatches[i]["eta"]}</td>
                                    <td><span className={"badge " + get_priority_badge(str(dispatches[i]["priority"]))}>{dispatches[i]["priority"]}</span></td>
                                    <td><span className={"badge " + get_status_badge(str(dispatches[i]["status"]))}>{dispatches[i]["status"]}</span></td>
                                    <td>
                                        <div className="flex gap-1">
                                            <button className="btn btn-ghost px-2 py-1 text-xs">Track</button>
                                            <button className="btn btn-ghost px-2 py-1 text-xs">Edit</button>
                                        </div>
                                    </td>
                                </tr>
                                for i in range(len(dispatches))
                            ]}
                        </tbody>
                    </table>
                </div>
            )}

            {active_tab == "schedule" and (
                <div className="card p-6">
                    <div className="text-sm font-bold text-foreground mb-4">Weekly Schedule Overview</div>
                    <div className="grid grid-cols-7 gap-2">
                        {[
                            <div key={str(i)} className="text-center">
                                <div className="text-xs text-muted-foreground mb-2">{["Mon","Tue","Wed","Thu","Fri","Sat","Sun"][i]}</div>
                                <div className="bg-muted rounded-lg p-2 min-h-[80px] flex flex-col gap-1">
                                    {i < 5 and (
                                        <div className="text-xs bg-primary/20 text-primary rounded px-1 py-0.5">
                                            {str(18 + i * 3)} trips
                                        </div>
                                    )}
                                    {i >= 5 and (
                                        <div className="text-xs bg-muted-foreground/20 text-muted-foreground rounded px-1 py-0.5">
                                            {str(8 + i)} trips
                                        </div>
                                    )}
                                </div>
                            </div>
                            for i in range(7)
                        ]}
                    </div>
                </div>
            )}

            {active_tab == "alerts" and (
                <div className="flex flex-col gap-3">
                    <div className="card p-4 border-l-4 border-l-red-500">
                        <div className="flex items-start justify-between">
                            <div>
                                <div className="text-sm font-bold text-foreground">🚨 Vehicle ORB-3341 — Low Fuel Alert</div>
                                <div className="text-xs text-muted-foreground mt-1">Fuel level at 12%. Nearest station: 8.4 km away.</div>
                            </div>
                            <span className="badge badge-danger">Critical</span>
                        </div>
                    </div>
                    <div className="card p-4 border-l-4 border-l-amber-500">
                        <div className="flex items-start justify-between">
                            <div>
                                <div className="text-sm font-bold text-foreground">⚠️ Driver DRV-005 — Hours of Service Warning</div>
                                <div className="text-xs text-muted-foreground mt-1">Tom Nakamura approaching 10-hour driving limit. 45 min remaining.</div>
                            </div>
                            <span className="badge badge-warning">Warning</span>
                        </div>
                    </div>
                    <div className="card p-4 border-l-4 border-l-blue-500">
                        <div className="flex items-start justify-between">
                            <div>
                                <div className="text-sm font-bold text-foreground">ℹ️ Route DSP-4820 — Traffic Delay Detected</div>
                                <div className="text-xs text-muted-foreground mt-1">Estimated 22-minute delay on I-95. Alternative route suggested.</div>
                            </div>
                            <span className="badge badge-info">Info</span>
                        </div>
                    </div>
                    <div className="card p-4 border-l-4 border-l-emerald-500">
                        <div className="flex items-start justify-between">
                            <div>
                                <div className="text-sm font-bold text-foreground">✅ DSP-4818 — Delivery Confirmed</div>
                                <div className="text-xs text-muted-foreground mt-1">Airport Cargo delivery completed 8 minutes ahead of schedule.</div>
                            </div>
                            <span className="badge badge-success">Success</span>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
