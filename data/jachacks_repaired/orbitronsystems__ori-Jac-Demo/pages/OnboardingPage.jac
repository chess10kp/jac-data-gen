import from "@jac/runtime" { useNavigate }

def ModuleToggle(mod: Any, modules: list, onToggle: Any) -> JsxElement {
    mod_id: str = str(mod["id"]);
    is_selected: bool = mod_id in modules;
    cls: str = "card p-4 text-left cursor-pointer border-2 " + ("border-primary" if is_selected else "border-border");

    def handle_click(e: MouseEvent) -> None {
        if onToggle { onToggle(mod_id); }
    }

    return (
        <button className={cls} onClick={handle_click}>
            <div className="text-2xl mb-2">{mod["icon"]}</div>
            <div className="text-xs font-bold text-foreground mb-1">{mod["name"]}</div>
            <div className="text-xs text-muted-foreground">{mod["desc"]}</div>
            {is_selected and (
                <div className="mt-2 text-xs text-primary font-bold">✓ Selected</div>
            )}
        </button>
    );
}

def:pub page() -> JsxElement {
    has current_step: int = 0;
    has company_name: str = "";
    has fleet_size: str = "";
    has industry: str = "";
    has contact_name: str = "";
    has contact_email: str = "";
    has modules: list = [];
    has completed: bool = False;

    nav = useNavigate();

    def handle_company(e: ChangeEvent) -> None {
        company_name = e.target.value;
    }

    def handle_fleet(e: ChangeEvent) -> None {
        fleet_size = e.target.value;
    }

    def handle_industry(e: ChangeEvent) -> None {
        industry = e.target.value;
    }

    def handle_contact_name(e: ChangeEvent) -> None {
        contact_name = e.target.value;
    }

    def handle_contact_email(e: ChangeEvent) -> None {
        contact_email = e.target.value;
    }

    def next_step(e: MouseEvent) -> None {
        if current_step < 3 {
            current_step = current_step + 1;
        } else {
            completed = True;
        }
    }

    def prev_step(e: MouseEvent) -> None {
        if current_step > 0 {
            current_step = current_step - 1;
        }
    }

    def go_dashboard(e: MouseEvent) -> None {
        nav("/dashboard");
    }

    def go_welcome(e: MouseEvent) -> None {
        nav("/");
    }

    steps = ["Company Info", "Fleet Details", "Module Selection", "Review & Launch"];
    step_icons = ["🏢", "🚛", "⚙️", "🚀"];

    all_modules = [
        {"id": "fleet", "name": "Fleet Management", "icon": "🚛", "desc": "Vehicle tracking & maintenance"},
        {"id": "driver", "name": "Driver Management", "icon": "👤", "desc": "Driver profiles & compliance"},
        {"id": "ops", "name": "Operations", "icon": "⚙️", "desc": "Dispatch & scheduling"},
        {"id": "ai", "name": "AI Intelligence Hub", "icon": "🧠", "desc": "Predictive analytics"},
        {"id": "telemetry", "name": "Real-time Telemetry", "icon": "📡", "desc": "Live sensor data"},
        {"id": "routing", "name": "Smart Routing", "icon": "🗺️", "desc": "Route optimization"},
        {"id": "analytics", "name": "Analytics & Reporting", "icon": "📊", "desc": "Business intelligence"},
        {"id": "monetization", "name": "Monetization", "icon": "💰", "desc": "Revenue & cost tracking"},
        {"id": "survey", "name": "Driver Survey & Rewards", "icon": "🏆", "desc": "Engagement programs"},
    ];

    def toggle_module(mod_id: str) -> None {
        if mod_id in modules {
            modules = [m for m in modules if m != mod_id];
        } else {
            modules = modules + [mod_id];
        }
    }

    if completed {
        return (
            <div className="onboarding-page">
                <div className="flex-1 flex flex-col items-center justify-center p-12 text-center">
                    <div className="text-7xl mb-6">🎉</div>
                    <h1 className="text-4xl font-black text-foreground mb-4">You're all set!</h1>
                    <p className="text-lg text-muted-foreground mb-8 max-w-md">
                        ORBITRON is configured for <strong className="text-foreground">{company_name if company_name else "your company"}</strong>.
                        Your fleet command center is ready.
                    </p>
                    <button className="btn btn-primary px-10 py-3 text-base" onClick={go_dashboard}>
                        🚀 Launch ORBITRON Dashboard
                    </button>
                </div>
            </div>
        );
    }

    return (
        <div className="onboarding-page">
            <div className="onboarding-sidebar">
                <div className="mb-8">
                    <div className="orbitron-logo mb-1">ORBITRON</div>
                    <div className="orbitron-tagline">Setup Wizard</div>
                </div>

                <div className="flex-1">
                    <div className="text-xs font-bold uppercase tracking-widest text-muted-foreground mb-4">Setup Progress</div>
                    {[
                        <div
                            key={str(i)}
                            className={"onboarding-step " + ("active" if i == current_step else ("done" if i < current_step else ""))}
                        >
                            <div className={"onboarding-step-num " + ("active" if i == current_step else ("done" if i < current_step else "pending"))}>
                                {"✓" if i < current_step else str(i + 1)}
                            </div>
                            <div>
                                <div className={"text-sm font-semibold " + ("text-foreground" if i == current_step else "text-muted-foreground")}>
                                    {steps[i]}
                                </div>
                                <div className="text-xs text-muted-foreground">{step_icons[i]}</div>
                            </div>
                        </div>
                        for i in range(len(steps))
                    ]}
                </div>

                <button className="btn btn-ghost w-full" onClick={go_welcome}>← Back to Home</button>
            </div>

            <div className="onboarding-main">
                <div className="onboarding-card">
                    <div className="mb-2 text-xs font-bold uppercase tracking-widest text-primary">
                        Step {str(current_step + 1)} of {str(len(steps))}
                    </div>
                    <h2 className="text-2xl font-black text-foreground mb-1">{steps[current_step]}</h2>
                    <p className="text-muted-foreground mb-8 text-sm">
                        {"Tell us about your organization" if current_step == 0 else ("Configure your fleet parameters" if current_step == 1 else ("Choose the modules you need" if current_step == 2 else "Review your configuration"))}
                    </p>

                    {current_step == 0 and (
                        <div className="flex flex-col gap-5">
                            <div>
                                <label className="label">Company Name</label>
                                <input className="input" type="text" value={company_name} onChange={handle_company} placeholder="e.g. Apex Logistics Inc." />
                            </div>
                            <div>
                                <label className="label">Contact Name</label>
                                <input className="input" type="text" value={contact_name} onChange={handle_contact_name} placeholder="Your full name" />
                            </div>
                            <div>
                                <label className="label">Work Email</label>
                                <input className="input" type="email" value={contact_email} onChange={handle_contact_email} placeholder="you@company.com" />
                            </div>
                        </div>
                    )}

                    {current_step == 1 and (
                        <div className="flex flex-col gap-5">
                            <div>
                                <label className="label">Fleet Size</label>
                                <select className="select" value={fleet_size} onChange={handle_fleet}>
                                    <option value="">Select fleet size...</option>
                                    <option value="1-25">1–25 vehicles</option>
                                    <option value="26-100">26–100 vehicles</option>
                                    <option value="101-500">101–500 vehicles</option>
                                    <option value="500+">500+ vehicles</option>
                                </select>
                            </div>
                            <div>
                                <label className="label">Industry</label>
                                <select className="select" value={industry} onChange={handle_industry}>
                                    <option value="">Select industry...</option>
                                    <option value="logistics">Logistics & Freight</option>
                                    <option value="transit">Public Transit</option>
                                    <option value="construction">Construction</option>
                                    <option value="delivery">Last-Mile Delivery</option>
                                    <option value="mining">Mining & Resources</option>
                                    <option value="other">Other</option>
                                </select>
                            </div>
                            <div className="card p-4">
                                <div className="text-sm font-semibold text-foreground mb-2">📍 GPS Integration</div>
                                <div className="text-xs text-muted-foreground">Real-time vehicle tracking will be enabled automatically based on your fleet size.</div>
                            </div>
                        </div>
                    )}

                    {current_step == 2 and (
                        <div className="grid grid-cols-3 gap-3">
                            <ModuleToggle mod={all_modules[0]} modules={modules} onToggle={toggle_module} />
                            <ModuleToggle mod={all_modules[1]} modules={modules} onToggle={toggle_module} />
                            <ModuleToggle mod={all_modules[2]} modules={modules} onToggle={toggle_module} />
                            <ModuleToggle mod={all_modules[3]} modules={modules} onToggle={toggle_module} />
                            <ModuleToggle mod={all_modules[4]} modules={modules} onToggle={toggle_module} />
                            <ModuleToggle mod={all_modules[5]} modules={modules} onToggle={toggle_module} />
                            <ModuleToggle mod={all_modules[6]} modules={modules} onToggle={toggle_module} />
                            <ModuleToggle mod={all_modules[7]} modules={modules} onToggle={toggle_module} />
                            <ModuleToggle mod={all_modules[8]} modules={modules} onToggle={toggle_module} />
                        </div>
                    )}

                    {current_step == 3 and (
                        <div className="flex flex-col gap-4">
                            <div className="card p-5">
                                <div className="text-xs font-bold uppercase tracking-widest text-muted-foreground mb-3">Organization</div>
                                <div className="flex flex-col gap-2">
                                    <div className="flex justify-between text-sm">
                                        <span className="text-muted-foreground">Company</span>
                                        <span className="text-foreground font-medium">{company_name if company_name else "—"}</span>
                                    </div>
                                    <div className="flex justify-between text-sm">
                                        <span className="text-muted-foreground">Contact</span>
                                        <span className="text-foreground font-medium">{contact_name if contact_name else "—"}</span>
                                    </div>
                                    <div className="flex justify-between text-sm">
                                        <span className="text-muted-foreground">Email</span>
                                        <span className="text-foreground font-medium">{contact_email if contact_email else "—"}</span>
                                    </div>
                                    <div className="flex justify-between text-sm">
                                        <span className="text-muted-foreground">Fleet Size</span>
                                        <span className="text-foreground font-medium">{fleet_size if fleet_size else "—"}</span>
                                    </div>
                                    <div className="flex justify-between text-sm">
                                        <span className="text-muted-foreground">Industry</span>
                                        <span className="text-foreground font-medium">{industry if industry else "—"}</span>
                                    </div>
                                </div>
                            </div>
                            <div className="card p-5">
                                <div className="text-xs font-bold uppercase tracking-widest text-muted-foreground mb-3">
                                    Selected Modules ({str(len(modules))})
                                </div>
                                {len(modules) == 0 and (
                                    <div className="text-sm text-muted-foreground">No modules selected — all modules will be enabled by default.</div>
                                )}
                                <div className="flex flex-wrap gap-2">
                                    {[
                                        <span key={modules[i]} className="badge badge-primary">{modules[i]}</span>
                                        for i in range(len(modules))
                                    ]}
                                </div>
                            </div>
                        </div>
                    )}

                    <div className="flex items-center justify-between mt-8">
                        <button
                            className={"btn btn-ghost " + ("opacity-0 pointer-events-none" if current_step == 0 else "")}
                            onClick={prev_step}
                        >
                            ← Previous
                        </button>
                        <button className="btn btn-primary px-8" onClick={next_step}>
                            {"🚀 Launch ORBITRON" if current_step == 3 else "Continue →"}
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
}
