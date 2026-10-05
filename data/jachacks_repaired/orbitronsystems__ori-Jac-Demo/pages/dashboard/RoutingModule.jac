def:pub RoutingModule() -> JsxElement {
    has optimizing: bool = False;
    has optimized: bool = False;
    has selected_route: int = 0;

    routes = [
        {"id": 1, "name": "Route Alpha", "origin": "Warehouse A", "dest": "Distribution Hub 3", "distance": 142, "duration": "2h 18m", "fuel": 48, "status": "optimal", "vehicles": 3, "savings": 12},
        {"id": 2, "name": "Route Beta", "origin": "Port Terminal", "dest": "Retail Hub East", "distance": 87, "duration": "1h 32m", "fuel": 29, "status": "delayed", "vehicles": 2, "savings": 0},
        {"id": 3, "name": "Route Gamma", "origin": "Supplier Dock B", "dest": "Warehouse C", "distance": 203, "duration": "3h 05m", "fuel": 67, "status": "optimal", "vehicles": 4, "savings": 23},
        {"id": 4, "name": "Route Delta", "origin": "Cold Storage", "dest": "Supermarket Chain", "distance": 56, "duration": "0h 58m", "fuel": 19, "status": "rerouted", "vehicles": 1, "savings": 8},
    ];

    def select_route(idx: int) -> None {
        selected_route = idx;
    }

    def select_r0(e: MouseEvent) -> None { select_route(0); }
    def select_r1(e: MouseEvent) -> None { select_route(1); }
    def select_r2(e: MouseEvent) -> None { select_route(2); }
    def select_r3(e: MouseEvent) -> None { select_route(3); }

    route_handlers = [select_r0, select_r1, select_r2, select_r3];

    async def run_optimize(e: MouseEvent) -> None {
        optimizing = True;
        optimized = False;
        optimizing = False;
        optimized = True;
    }

    def get_status_badge(s: str) -> str {
        if s == "optimal" { return "badge-success"; }
        if s == "delayed" { return "badge-danger"; }
        return "badge-warning";
    }

    sel = routes[selected_route];
    sel_name: str = str(sel["name"]);
    sel_origin: str = str(sel["origin"]);
    sel_dest: str = str(sel["dest"]);
    sel_distance: int = int(sel["distance"]);
    sel_duration: str = str(sel["duration"]);
    sel_fuel: int = int(sel["fuel"]);
    sel_status: str = str(sel["status"]);
    sel_vehicles: int = int(sel["vehicles"]);
    sel_savings: int = int(sel["savings"]);

    return (
        <div>
            <div className="module-header">
                <div className="flex items-center justify-between">
                    <div>
                        <h1 className="module-title">🗺️ Smart Routing</h1>
                        <p className="module-subtitle">AI-powered route optimization with real-time traffic and load balancing</p>
                    </div>
                    <button className="btn btn-primary" onClick={run_optimize}>
                        {"⏳ Optimizing..." if optimizing else "⚡ Optimize All Routes"}
                    </button>
                </div>
            </div>

            {optimized and (
                <div className="result-box mb-5">
                    ✅ Route optimization complete — 12 routes updated, estimated 340L fuel saved today
                </div>
            )}

            <div className="stats-grid-4 mb-6">
                <div className="stat-card">
                    <div className="stat-label">Active Routes</div>
                    <div className="stat-value">{str(len(routes))}</div>
                    <div className="stat-change">Currently running</div>
                </div>
                <div className="stat-card">
                    <div className="stat-label">Fuel Saved Today</div>
                    <div className="stat-value text-emerald-400">340L</div>
                    <div className="stat-change up">↑ 18% vs baseline</div>
                </div>
                <div className="stat-card">
                    <div className="stat-label">Avg Route Score</div>
                    <div className="stat-value text-primary">91</div>
                    <div className="stat-change up">↑ Excellent</div>
                </div>
                <div className="stat-card">
                    <div className="stat-label">Reroutes Today</div>
                    <div className="stat-value text-amber-400">7</div>
                    <div className="stat-change">Traffic-triggered</div>
                </div>
            </div>

            <div className="grid grid-cols-3 gap-4">
                <div className="col-span-1">
                    <div className="card overflow-hidden">
                        <div className="px-4 py-3 border-b border-border text-sm font-bold text-foreground">Route List</div>
                        <div className="flex flex-col">
                            {[
                                <button
                                    key={str(routes[i]["id"])}
                                    className={"w-full text-left px-4 py-4 border-b border-border transition-all " + ("bg-primary/10 border-l-2 border-l-primary" if selected_route == i else "hover:bg-muted")}
                                    onClick={route_handlers[i]}
                                >
                                    <div className="flex items-center justify-between mb-1">
                                        <div className="text-sm font-bold text-foreground">{routes[i]["name"]}</div>
                                        <span className={"badge text-xs " + get_status_badge(str(routes[i]["status"]))}>{routes[i]["status"]}</span>
                                    </div>
                                    <div className="text-xs text-muted-foreground">{routes[i]["origin"]} → {routes[i]["dest"]}</div>
                                    <div className="text-xs text-muted-foreground mt-1">{str(routes[i]["distance"])} km · {routes[i]["duration"]}</div>
                                </button>
                                for i in range(len(routes))
                            ]}
                        </div>
                    </div>
                </div>

                <div className="col-span-2 flex flex-col gap-4">
                    <div className="map-container rounded-xl">
                        <div className="map-grid"></div>
                        <div className="absolute inset-0 flex items-center justify-center">
                            <div className="text-center">
                                <div className="text-4xl mb-3">🗺️</div>
                                <div className="text-sm font-bold text-foreground">{sel_name}</div>
                                <div className="text-xs text-muted-foreground mt-1">{sel_origin} → {sel_dest}</div>
                                <div className="flex items-center gap-4 mt-3 text-xs">
                                    <span className="text-primary font-mono">{str(sel_distance)} km</span>
                                    <span className="text-muted-foreground">{sel_duration}</span>
                                    <span className="text-amber-400">{str(sel_fuel)}L fuel</span>
                                </div>
                            </div>
                        </div>
                        <div className="absolute top-4 right-4">
                            <span className={"badge " + get_status_badge(sel_status)}>{sel_status}</span>
                        </div>
                    </div>

                    <div className="grid grid-cols-3 gap-3">
                        <div className="card p-4 text-center">
                            <div className="text-xs text-muted-foreground mb-1">Vehicles Assigned</div>
                            <div className="text-2xl font-black text-foreground">{str(sel_vehicles)}</div>
                        </div>
                        <div className="card p-4 text-center">
                            <div className="text-xs text-muted-foreground mb-1">Fuel Consumption</div>
                            <div className="text-2xl font-black text-amber-400">{str(sel_fuel)}L</div>
                        </div>
                        <div className="card p-4 text-center">
                            <div className="text-xs text-muted-foreground mb-1">Fuel Savings</div>
                            <div className="text-2xl font-black text-emerald-400">{str(sel_savings)}L</div>
                        </div>
                    </div>

                    <div className="card p-5">
                        <div className="text-sm font-bold text-foreground mb-3">🚦 Traffic Conditions</div>
                        <div className="flex flex-col gap-2">
                            <div className="flex items-center justify-between text-sm">
                                <span className="text-muted-foreground">I-95 North (Mile 120–145)</span>
                                <span className="badge badge-success">Clear</span>
                            </div>
                            <div className="flex items-center justify-between text-sm">
                                <span className="text-muted-foreground">Route 66 Sector 7</span>
                                <span className="badge badge-warning">Moderate</span>
                            </div>
                            <div className="flex items-center justify-between text-sm">
                                <span className="text-muted-foreground">Ring Road Junction 5</span>
                                <span className="badge badge-danger">Heavy</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}
