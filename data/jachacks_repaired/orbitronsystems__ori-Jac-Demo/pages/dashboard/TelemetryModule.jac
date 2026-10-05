def:pub TelemetryModule() -> JsxElement {
    has selected_vehicle: str = "ORB-2847";
    has live: bool = True;

    def select_orb2847(e: MouseEvent) -> None {
        selected_vehicle = "ORB-2847";
    }

    def select_orb1923(e: MouseEvent) -> None {
        selected_vehicle = "ORB-1923";
    }

    def select_orb0892(e: MouseEvent) -> None {
        selected_vehicle = "ORB-0892";
    }

    def select_orb2156(e: MouseEvent) -> None {
        selected_vehicle = "ORB-2156";
    }

    def toggle_live(e: MouseEvent) -> None {
        live = not live;
    }

    vehicle_data = {
        "ORB-2847": {"speed": 62, "rpm": 2340, "fuel": 78, "temp": 91, "lat": 40.7128, "lng": -74.0060, "driver": "Marcus Chen", "odometer": 124847, "battery": 98, "tire_fl": 34, "tire_fr": 35, "tire_rl": 33, "tire_rr": 34},
        "ORB-1923": {"speed": 55, "rpm": 1980, "fuel": 45, "temp": 88, "lat": 35.6762, "lng": -139.6503, "driver": "Sarah Williams", "odometer": 98321, "battery": 94, "tire_fl": 36, "tire_fr": 36, "tire_rl": 35, "tire_rr": 35},
        "ORB-0892": {"speed": 70, "rpm": 2780, "fuel": 91, "temp": 94, "lat": 37.7749, "lng": -122.4194, "driver": "Aisha Patel", "odometer": 187654, "battery": 100, "tire_fl": 33, "tire_fr": 34, "tire_rl": 33, "tire_rr": 34},
        "ORB-2156": {"speed": 48, "rpm": 1650, "fuel": 33, "temp": 86, "lat": 51.5074, "lng": -0.1278, "driver": "Elena Vasquez", "odometer": 143210, "battery": 87, "tire_fl": 35, "tire_fr": 35, "tire_rl": 34, "tire_rr": 35},
    };

    vdata = vehicle_data[selected_vehicle] if selected_vehicle in vehicle_data else vehicle_data["ORB-2847"];
    speed: int = int(vdata["speed"]);
    rpm: int = int(vdata["rpm"]);
    fuel: int = int(vdata["fuel"]);
    temp: int = int(vdata["temp"]);
    driver: str = str(vdata["driver"]);
    odometer: int = int(vdata["odometer"]);
    battery: int = int(vdata["battery"]);
    tire_fl: int = int(vdata["tire_fl"]);
    tire_fr: int = int(vdata["tire_fr"]);
    tire_rl: int = int(vdata["tire_rl"]);
    tire_rr: int = int(vdata["tire_rr"]);

    vehicles = ["ORB-2847", "ORB-1923", "ORB-0892", "ORB-2156"];
    handlers = [select_orb2847, select_orb1923, select_orb0892, select_orb2156];

    fuel_color: str = "text-emerald-400" if fuel > 50 else ("text-amber-400" if fuel > 20 else "text-red-400");
    temp_color: str = "text-emerald-400" if temp < 95 else "text-red-400";

    return (
        <div>
            <div className="module-header">
                <div className="flex items-center justify-between">
                    <div>
                        <h1 className="module-title">📡 Real-time Telemetry</h1>
                        <p className="module-subtitle">Live sensor data, GPS tracking, and vehicle diagnostics</p>
                    </div>
                    <div className="flex items-center gap-3">
                        <button
                            className={"btn text-xs px-4 " + ("btn-primary" if live else "btn-ghost")}
                            onClick={toggle_live}
                        >
                            {("🔴 LIVE" if live else "⏸ Paused")}
                        </button>
                    </div>
                </div>
            </div>

            <div className="flex gap-2 mb-5">
                {[
                    <button
                        key={vehicles[i]}
                        className={"btn text-xs px-4 " + ("btn-primary" if selected_vehicle == vehicles[i] else "btn-ghost")}
                        onClick={handlers[i]}
                    >
                        {vehicles[i]}
                    </button>
                    for i in range(len(vehicles))
                ]}
            </div>

            <div className="grid grid-cols-4 gap-4 mb-5">
                <div className="card p-5 text-center">
                    <div className="text-xs font-bold uppercase tracking-widest text-muted-foreground mb-2">Speed</div>
                    <div className="text-5xl font-black text-foreground mb-1" style={{"fontVariantNumeric": "tabular-nums"}}>{str(speed)}</div>
                    <div className="text-xs text-muted-foreground">km/h</div>
                    <div className="progress-bar mt-3">
                        <div className="progress-fill" style={{"width": str(min(speed, 120) * 100 // 120) + "%"}}></div>
                    </div>
                </div>
                <div className="card p-5 text-center">
                    <div className="text-xs font-bold uppercase tracking-widest text-muted-foreground mb-2">Engine RPM</div>
                    <div className="text-5xl font-black text-foreground mb-1" style={{"fontVariantNumeric": "tabular-nums"}}>{str(rpm)}</div>
                    <div className="text-xs text-muted-foreground">rpm</div>
                    <div className="progress-bar mt-3">
                        <div className="progress-fill" style={{"width": str(rpm * 100 // 4000) + "%"}}></div>
                    </div>
                </div>
                <div className="card p-5 text-center">
                    <div className="text-xs font-bold uppercase tracking-widest text-muted-foreground mb-2">Fuel Level</div>
                    <div className={"text-5xl font-black mb-1 " + fuel_color} style={{"fontVariantNumeric": "tabular-nums"}}>{str(fuel)}%</div>
                    <div className="text-xs text-muted-foreground">remaining</div>
                    <div className="progress-bar mt-3">
                        <div className="progress-fill" style={{"width": str(fuel) + "%"}}></div>
                    </div>
                </div>
                <div className="card p-5 text-center">
                    <div className="text-xs font-bold uppercase tracking-widest text-muted-foreground mb-2">Engine Temp</div>
                    <div className={"text-5xl font-black mb-1 " + temp_color} style={{"fontVariantNumeric": "tabular-nums"}}>{str(temp)}°</div>
                    <div className="text-xs text-muted-foreground">celsius</div>
                    <div className="progress-bar mt-3">
                        <div className="progress-fill" style={{"width": str(temp * 100 // 120) + "%"}}></div>
                    </div>
                </div>
            </div>

            <div className="grid grid-cols-3 gap-4 mb-5">
                <div className="col-span-2 map-container rounded-xl">
                    <div className="map-grid"></div>
                    <div className="absolute inset-0 flex items-center justify-center">
                        <div className="text-center">
                            <div className="text-4xl mb-3">📍</div>
                            <div className="text-sm font-bold text-foreground">{selected_vehicle}</div>
                            <div className="text-xs text-muted-foreground mt-1">{driver}</div>
                            <div className="text-xs text-primary mt-2 font-mono">
                                {str(vdata["lat"])}°N, {str(vdata["lng"])}°W
                            </div>
                        </div>
                    </div>
                    <div className="absolute top-4 left-4 flex items-center gap-2 px-3 py-1.5 rounded-full text-xs font-semibold text-emerald-400" style={{"background": "rgba(16,185,129,0.15)", "border": "1px solid rgba(16,185,129,0.3)"}}>
                        <span className="w-2 h-2 rounded-full bg-emerald-400 inline-block"></span>
                        GPS Active
                    </div>
                </div>

                <div className="flex flex-col gap-4">
                    <div className="card p-4">
                        <div className="text-xs font-bold uppercase tracking-widest text-muted-foreground mb-3">Vehicle Info</div>
                        <div className="flex flex-col gap-2 text-sm">
                            <div className="flex justify-between">
                                <span className="text-muted-foreground">Driver</span>
                                <span className="text-foreground font-medium">{driver}</span>
                            </div>
                            <div className="flex justify-between">
                                <span className="text-muted-foreground">Odometer</span>
                                <span className="text-foreground font-mono">{str(odometer)} km</span>
                            </div>
                            <div className="flex justify-between">
                                <span className="text-muted-foreground">Battery</span>
                                <span className="text-foreground font-mono">{str(battery)}%</span>
                            </div>
                        </div>
                    </div>

                    <div className="card p-4">
                        <div className="text-xs font-bold uppercase tracking-widest text-muted-foreground mb-3">Tire Pressure (PSI)</div>
                        <div className="grid grid-cols-2 gap-2">
                            <div className="bg-muted rounded-lg p-2 text-center">
                                <div className="text-xs text-muted-foreground">FL</div>
                                <div className="text-lg font-black text-foreground">{str(tire_fl)}</div>
                            </div>
                            <div className="bg-muted rounded-lg p-2 text-center">
                                <div className="text-xs text-muted-foreground">FR</div>
                                <div className="text-lg font-black text-foreground">{str(tire_fr)}</div>
                            </div>
                            <div className="bg-muted rounded-lg p-2 text-center">
                                <div className="text-xs text-muted-foreground">RL</div>
                                <div className="text-lg font-black text-foreground">{str(tire_rl)}</div>
                            </div>
                            <div className="bg-muted rounded-lg p-2 text-center">
                                <div className="text-xs text-muted-foreground">RR</div>
                                <div className="text-lg font-black text-foreground">{str(tire_rr)}</div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div className="card p-5">
                <div className="text-sm font-bold text-foreground mb-4">📈 Speed History (Last 30 min)</div>
                <div className="flex items-end gap-1 h-20">
                    {[
                        <div
                            key={str(i)}
                            className="flex-1 rounded-t-sm"
                            style={{"height": str(30 + (i * 7 + speed) % 60) + "%", "background": "linear-gradient(180deg, #6366f1 0%, rgba(99,102,241,0.3) 100%)"}}
                        ></div>
                        for i in range(30)
                    ]}
                </div>
                <div className="flex justify-between text-xs text-muted-foreground mt-2">
                    <span>30 min ago</span>
                    <span>15 min ago</span>
                    <span>Now</span>
                </div>
            </div>
        </div>
    );
}
