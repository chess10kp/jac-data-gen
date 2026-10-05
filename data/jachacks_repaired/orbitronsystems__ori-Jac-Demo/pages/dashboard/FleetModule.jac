def VehicleRow(vehicle: Any, onSelect: Any, getStatusBadge: Any) -> JsxElement {
    vid: int = int(vehicle["id"]);
    plate: str = str(vehicle["plate"]);
    vtype: str = str(vehicle["type"]);
    driver: str = str(vehicle["driver"]);
    status: str = str(vehicle["status"]);
    fuel: int = int(vehicle["fuel"]);
    speed: int = int(vehicle["speed"]);
    location: str = str(vehicle["location"]);
    badge_cls: str = "badge " + str(getStatusBadge(status));
    fuel_pct: str = str(fuel) + "%";

    def handle_click(e: MouseEvent) -> None {
        if onSelect { onSelect(vid); }
    }

    return (
        <tr className="cursor-pointer" onClick={handle_click}>
            <td className="font-mono font-bold text-primary">{plate}</td>
            <td className="text-muted-foreground text-xs">{vtype}</td>
            <td className="font-medium">{driver}</td>
            <td><span className={badge_cls}>{status}</span></td>
            <td>
                <div className="flex items-center gap-2">
                    <div className="progress-bar w-16">
                        <div className="progress-fill" style={{"width": fuel_pct}}></div>
                    </div>
                    <span className="text-xs text-muted-foreground">{str(fuel)}%</span>
                </div>
            </td>
            <td className="font-mono text-sm">{str(speed)} km/h</td>
            <td className="text-xs text-muted-foreground">{location}</td>
            <td>
                <div className="flex gap-1">
                    <button className="btn btn-ghost px-2 py-1 text-xs">Track</button>
                    <button className="btn btn-ghost px-2 py-1 text-xs">Edit</button>
                </div>
            </td>
        </tr>
    );
}

def:pub FleetModule() -> JsxElement {
    has selected_vehicle: int = -1;
    has filter_status: str = "all";

    vehicles = [
        {"id": 1, "plate": "ORB-2847", "driver": "Marcus Chen", "status": "active", "fuel": 78, "speed": 62, "location": "I-95 North, Mile 142", "type": "Heavy Truck"},
        {"id": 2, "plate": "ORB-1923", "driver": "Sarah Williams", "status": "active", "fuel": 45, "speed": 55, "location": "Route 66, Sector 7", "type": "Delivery Van"},
        {"id": 3, "plate": "ORB-3341", "driver": "James Rodriguez", "status": "maintenance", "fuel": 12, "speed": 0, "location": "Depot Bay 3", "type": "Heavy Truck"},
        {"id": 4, "plate": "ORB-0892", "driver": "Aisha Patel", "status": "active", "fuel": 91, "speed": 70, "location": "Highway 101, Exit 28", "type": "Tanker"},
        {"id": 5, "plate": "ORB-4417", "driver": "Tom Nakamura", "status": "idle", "fuel": 65, "speed": 0, "location": "Warehouse District", "type": "Delivery Van"},
        {"id": 6, "plate": "ORB-2156", "driver": "Elena Vasquez", "status": "active", "fuel": 33, "speed": 48, "location": "Ring Road, Junction 5", "type": "Refrigerated"},
    ];

    def handle_filter(e: ChangeEvent) -> None {
        filter_status = e.target.value;
    }

    def select_vehicle(vid: int) -> None {
        selected_vehicle = vid if selected_vehicle != vid else -1;
    }

    def get_status_badge(status: str) -> str {
        if status == "active" { return "badge-success"; }
        if status == "maintenance" { return "badge-danger"; }
        return "badge-warning";
    }

    active_count: int = len([v for v in vehicles if v["status"] == "active"]);
    maint_count: int = len([v for v in vehicles if v["status"] == "maintenance"]);
    idle_count: int = len([v for v in vehicles if v["status"] == "idle"]);

    filtered = [v for v in vehicles if filter_status == "all" or v["status"] == filter_status];

    return (
        <div>
            <div className="module-header">
                <div className="flex items-center justify-between">
                    <div>
                        <h1 className="module-title">🚛 Fleet Management</h1>
                        <p className="module-subtitle">Monitor and manage your entire vehicle fleet in real-time</p>
                    </div>
                    <div className="flex gap-3">
                        <select className="select w-40" value={filter_status} onChange={handle_filter}>
                            <option value="all">All Vehicles</option>
                            <option value="active">Active</option>
                            <option value="idle">Idle</option>
                            <option value="maintenance">Maintenance</option>
                        </select>
                        <button className="btn btn-primary">+ Add Vehicle</button>
                    </div>
                </div>
            </div>

            <div className="stats-grid-4 mb-6">
                <div className="stat-card">
                    <div className="stat-label">Total Fleet</div>
                    <div className="stat-value">{str(len(vehicles))}</div>
                    <div className="stat-change up">↑ 3 this month</div>
                </div>
                <div className="stat-card">
                    <div className="stat-label">Active Now</div>
                    <div className="stat-value text-emerald-400">{str(active_count)}</div>
                    <div className="stat-change up">↑ 98.4% uptime</div>
                </div>
                <div className="stat-card">
                    <div className="stat-label">In Maintenance</div>
                    <div className="stat-value text-red-400">{str(maint_count)}</div>
                    <div className="stat-change down">↓ 2 scheduled</div>
                </div>
                <div className="stat-card">
                    <div className="stat-label">Idle</div>
                    <div className="stat-value text-amber-400">{str(idle_count)}</div>
                    <div className="stat-change">Awaiting dispatch</div>
                </div>
            </div>

            <div className="card overflow-hidden mb-6">
                <div className="px-5 py-4 border-b border-border flex items-center justify-between">
                    <div className="text-sm font-bold text-foreground">Vehicle Registry</div>
                    <div className="text-xs text-muted-foreground">{str(len(filtered))} vehicles shown</div>
                </div>
                <table className="data-table">
                    <thead>
                        <tr>
                            <th>Plate</th>
                            <th>Type</th>
                            <th>Driver</th>
                            <th>Status</th>
                            <th>Fuel</th>
                            <th>Speed</th>
                            <th>Location</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        {[
                            <VehicleRow key={str(filtered[i]["id"])} vehicle={filtered[i]} onSelect={select_vehicle} getStatusBadge={get_status_badge} />
                            for i in range(len(filtered))
                        ]}
                    </tbody>
                </table>
            </div>

            <div className="grid grid-cols-2 gap-4">
                <div className="card p-5">
                    <div className="text-sm font-bold text-foreground mb-4">🔧 Maintenance Schedule</div>
                    <div className="flex flex-col gap-3">
                        <div className="flex items-center justify-between p-3 rounded-lg bg-muted">
                            <div>
                                <div className="text-sm font-medium text-foreground">ORB-3341 — Oil Change</div>
                                <div className="text-xs text-muted-foreground">Due: Today</div>
                            </div>
                            <span className="badge badge-danger">Overdue</span>
                        </div>
                        <div className="flex items-center justify-between p-3 rounded-lg bg-muted">
                            <div>
                                <div className="text-sm font-medium text-foreground">ORB-2847 — Tire Rotation</div>
                                <div className="text-xs text-muted-foreground">Due: Dec 28</div>
                            </div>
                            <span className="badge badge-warning">Soon</span>
                        </div>
                        <div className="flex items-center justify-between p-3 rounded-lg bg-muted">
                            <div>
                                <div className="text-sm font-medium text-foreground">ORB-0892 — Annual Inspection</div>
                                <div className="text-xs text-muted-foreground">Due: Jan 15</div>
                            </div>
                            <span className="badge badge-info">Scheduled</span>
                        </div>
                    </div>
                </div>
                <div className="card p-5">
                    <div className="text-sm font-bold text-foreground mb-4">⛽ Fuel Consumption</div>
                    <div className="flex items-end gap-2 h-32">
                        <div className="chart-bar" style={{"height": "60%"}}></div>
                        <div className="chart-bar" style={{"height": "80%"}}></div>
                        <div className="chart-bar" style={{"height": "45%"}}></div>
                        <div className="chart-bar" style={{"height": "90%"}}></div>
                        <div className="chart-bar" style={{"height": "70%"}}></div>
                        <div className="chart-bar" style={{"height": "55%"}}></div>
                        <div className="chart-bar" style={{"height": "85%"}}></div>
                    </div>
                    <div className="flex justify-between text-xs text-muted-foreground mt-2">
                        <span>Mon</span><span>Tue</span><span>Wed</span><span>Thu</span><span>Fri</span><span>Sat</span><span>Sun</span>
                    </div>
                    <div className="mt-3 flex items-center justify-between">
                        <span className="text-xs text-muted-foreground">Weekly avg</span>
                        <span className="text-sm font-bold text-foreground">4,821 L</span>
                    </div>
                </div>
            </div>
        </div>
    );
}
