def DriverCard(driver: Any) -> JsxElement {
    name: str = str(driver["name"]);
    id_str: str = str(driver["id"]);
    status: str = str(driver["status"]);
    score: int = int(driver["score"]);
    trips: int = int(driver["trips"]);
    hours: str = str(driver["hours"]);
    license: str = str(driver["license"]);
    badge_cls: str = "badge " + ("badge-success" if status == "on-duty" else ("badge-warning" if status == "off-duty" else "badge-danger"));
    score_color: str = "text-emerald-400" if score >= 90 else ("text-amber-400" if score >= 75 else "text-red-400");

    return (
        <div className="card p-5">
            <div className="flex items-start justify-between mb-4">
                <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full bg-primary/20 flex items-center justify-center text-primary font-bold text-sm">
                        {name[0]}
                    </div>
                    <div>
                        <div className="text-sm font-bold text-foreground">{name}</div>
                        <div className="text-xs text-muted-foreground">ID: {id_str}</div>
                    </div>
                </div>
                <span className={badge_cls}>{status}</span>
            </div>
            <div className="grid grid-cols-3 gap-3 mb-4">
                <div className="text-center">
                    <div className={"text-xl font-black " + score_color}>{str(score)}</div>
                    <div className="text-xs text-muted-foreground">Safety Score</div>
                </div>
                <div className="text-center">
                    <div className="text-xl font-black text-foreground">{str(trips)}</div>
                    <div className="text-xs text-muted-foreground">Trips</div>
                </div>
                <div className="text-center">
                    <div className="text-xl font-black text-foreground">{hours}</div>
                    <div className="text-xs text-muted-foreground">Hours</div>
                </div>
            </div>
            <div className="flex items-center justify-between text-xs">
                <span className="text-muted-foreground">License: <span className="text-foreground font-mono">{license}</span></span>
                <div className="flex gap-1">
                    <button className="btn btn-ghost px-2 py-1 text-xs">Profile</button>
                    <button className="btn btn-ghost px-2 py-1 text-xs">Message</button>
                </div>
            </div>
        </div>
    );
}

def:pub DriverModule() -> JsxElement {
    has search: str = "";
    has view_mode: str = "grid";

    drivers = [
        {"id": "DRV-001", "name": "Marcus Chen", "status": "on-duty", "score": 94, "trips": 1247, "hours": "8.2h", "license": "CDL-A"},
        {"id": "DRV-002", "name": "Sarah Williams", "status": "on-duty", "score": 88, "trips": 983, "hours": "6.5h", "license": "CDL-B"},
        {"id": "DRV-003", "name": "James Rodriguez", "status": "off-duty", "score": 91, "trips": 2104, "hours": "0h", "license": "CDL-A"},
        {"id": "DRV-004", "name": "Aisha Patel", "status": "on-duty", "score": 97, "trips": 1876, "hours": "7.1h", "license": "CDL-A"},
        {"id": "DRV-005", "name": "Tom Nakamura", "status": "off-duty", "score": 72, "trips": 654, "hours": "0h", "license": "CDL-B"},
        {"id": "DRV-006", "name": "Elena Vasquez", "status": "on-duty", "score": 85, "trips": 1432, "hours": "5.8h", "license": "CDL-A"},
        {"id": "DRV-007", "name": "David Kim", "status": "suspended", "score": 61, "trips": 321, "hours": "0h", "license": "CDL-B"},
        {"id": "DRV-008", "name": "Priya Sharma", "status": "on-duty", "score": 93, "trips": 1654, "hours": "9.0h", "license": "CDL-A"},
    ];

    def handle_search(e: ChangeEvent) -> None {
        search = e.target.value;
    }

    def set_grid(e: MouseEvent) -> None {
        view_mode = "grid";
    }

    def set_list(e: MouseEvent) -> None {
        view_mode = "list";
    }

    on_duty: int = len([d for d in drivers if d["status"] == "on-duty"]);
    avg_score: int = int(sum([int(d["score"]) for d in drivers]) / len(drivers));

    filtered = [d for d in drivers if not search or search.lower() in str(d["name"]).lower()];

    return (
        <div>
            <div className="module-header">
                <div className="flex items-center justify-between">
                    <div>
                        <h1 className="module-title">👤 Driver Management</h1>
                        <p className="module-subtitle">Driver profiles, compliance, and performance tracking</p>
                    </div>
                    <button className="btn btn-primary">+ Add Driver</button>
                </div>
            </div>

            <div className="stats-grid-4 mb-6">
                <div className="stat-card">
                    <div className="stat-label">Total Drivers</div>
                    <div className="stat-value">{str(len(drivers))}</div>
                    <div className="stat-change up">↑ 2 new this week</div>
                </div>
                <div className="stat-card">
                    <div className="stat-label">On Duty</div>
                    <div className="stat-value text-emerald-400">{str(on_duty)}</div>
                    <div className="stat-change">Active right now</div>
                </div>
                <div className="stat-card">
                    <div className="stat-label">Avg Safety Score</div>
                    <div className="stat-value text-primary">{str(avg_score)}</div>
                    <div className="stat-change up">↑ 3pts this month</div>
                </div>
                <div className="stat-card">
                    <div className="stat-label">Compliance Rate</div>
                    <div className="stat-value text-emerald-400">96%</div>
                    <div className="stat-change up">↑ All certs valid</div>
                </div>
            </div>

            <div className="flex items-center gap-3 mb-5">
                <input
                    className="input flex-1 max-w-xs"
                    type="text"
                    placeholder="Search drivers..."
                    value={search}
                    onChange={handle_search}
                />
                <div className="flex gap-1 border border-border rounded-lg p-1">
                    <button className={"btn btn-ghost px-3 py-1.5 text-xs " + ("bg-muted" if view_mode == "grid" else "")} onClick={set_grid}>⊞ Grid</button>
                    <button className={"btn btn-ghost px-3 py-1.5 text-xs " + ("bg-muted" if view_mode == "list" else "")} onClick={set_list}>☰ List</button>
                </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
                {[
                    <DriverCard key={str(filtered[i]["id"])} driver={filtered[i]} />
                    for i in range(len(filtered))
                ]}
            </div>
        </div>
    );
}
