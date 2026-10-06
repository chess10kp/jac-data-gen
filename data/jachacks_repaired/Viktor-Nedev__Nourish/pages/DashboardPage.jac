import from "@jac/runtime" { useNavigate, jacLogout, jacIsLoggedIn }
import from "lucide-react" {
    Building2, Home, Package, CheckCircle2, Truck, Scale,
    Play, Plus, RefreshCw, LogOut, X, Leaf,
    Clock, CheckCircle, AlertCircle, Car, Terminal
}
import from ..services.nourish_api {
    DashboardStats, DonationInfo, ShelterInfo, DispatchResult, VolunteerInfo,
    get_dashboard, get_donations, get_shelters, get_volunteers,
    add_donation, run_dispatch, reset_ecosystem
}

def:pub page() -> JsxElement {
    # Core data state
    has stats:      DashboardStats | None = None;
    has donations:  list[DonationInfo]   = [];
    has shelters:   list[ShelterInfo]    = [];
    has volunteers: list[VolunteerInfo]  = [];
    has loading:    bool = True;
    has error:      str  = "";

    # Dispatch animation state
    has dispatching:    bool = False;
    has dispatch_step:  int  = 0;
    has log_lines:      list[str] = [];
    has dispatch_result: DispatchResult | None = None;

    # Modal state
    has show_modal:   bool = False;
    has form_food:    str  = "vegetables";
    has form_qty:     str  = "20";
    has form_expiry:  str  = "2099-12-31T18:00:00";
    has form_biz:     str  = "FreshMart Supermarket";
    has form_loading: bool = False;
    has form_error:   str  = "";

    navigate = useNavigate();

    async def load_data() -> None {
        loading = True;
        error = "";
        try {
            stats      = await get_dashboard();
            donations  = await get_donations();
            shelters   = await get_shelters();
            volunteers = await get_volunteers();
        } except Exception as ex {
            error = "Failed to load data. Please refresh.";
        }
        loading = False;
    }

    async can with entry {
        if jacIsLoggedIn() {
            await load_data();
        }
    }

    # Sequential dispatch animation — each step fires when dispatch_step changes
    async can with [dispatch_step] entry {
        if dispatch_step == 1 {
            log_lines = ["[Supply Agent] Parsing incoming payload from Business nodes..."];
            setTimeout(lambda -> None { dispatch_step = 2; }, 1000);
        } elif dispatch_step == 2 {
            log_lines = log_lines + ["[Demand Agent] Mapping current shelter capacities and requirements..."];
            setTimeout(lambda -> None { dispatch_step = 3; }, 1000);
        } elif dispatch_step == 3 {
            log_lines = log_lines + ["[Logistics Agent] Route optimization complete. Assigning volunteers..."];
            setTimeout(lambda -> None { dispatch_step = 4; }, 1000);
        } elif dispatch_step == 4 {
            result = await run_dispatch();
            dispatch_result = result;
            await load_data();
            dispatching = False;
            dispatch_step = 0;
        }
    }

    def handle_logout(e: MouseEvent) -> None {
        jacLogout();
        navigate("/login");
    }

    def handle_start_dispatch(e: MouseEvent) -> None {
        if dispatching { return; }
        dispatching = True;
        log_lines = [];
        dispatch_result = None;
        dispatch_step = 1;
    }

    async def handle_reset(e: MouseEvent) -> None {
        loading = True;
        dispatch_result = None;
        log_lines = [];
        try {
            stats      = await reset_ecosystem();
            donations  = await get_donations();
            shelters   = await get_shelters();
            volunteers = await get_volunteers();
        } except Exception as ex {
            error = "Reset failed.";
        }
        loading = False;
    }

    def open_modal(e: MouseEvent) -> None {
        show_modal = True;
        form_error = "";
    }

    def close_modal(e: MouseEvent) -> None {
        show_modal = False;
        form_error = "";
    }

    def handle_food(e: ChangeEvent) -> None    { form_food   = e.target.value; }
    def handle_qty(e: ChangeEvent) -> None     { form_qty    = e.target.value; }
    def handle_expiry(e: ChangeEvent) -> None  { form_expiry = e.target.value; }
    def handle_biz(e: ChangeEvent) -> None     { form_biz    = e.target.value; }

    async def handle_add(e: FormEvent) -> None {
        e.preventDefault();
        form_loading = True;
        form_error = "";
        try {
            food_type: str     = form_food;
            quantity: int      = int(form_qty) if form_qty else 0;
            expiry_time: str   = form_expiry;
            business_name: str = form_biz;
            await add_donation(food_type, quantity, expiry_time, business_name);
            show_modal = False;
            await load_data();
        } except Exception as ex {
            form_error = "Failed to add donation. Please try again.";
        }
        form_loading = False;
    }

    def badge_cls(status: str) -> str {
        if status == "matched" { return "badge badge-matched"; }
        if status == "expired" { return "badge badge-expired"; }
        return "badge badge-pending";
    }

    def badge_lbl(status: str) -> str {
        if status == "matched" { return "Matched"; }
        if status == "expired" { return "Expired"; }
        return "Pending";
    }

    # Pull typed locals for safe JSX access
    s_biz:  int = stats.businesses if stats is not None else 0;
    s_sh:   int = stats.shelters if stats is not None else 0;
    s_pend: int = stats.pending_donations if stats is not None else 0;
    s_mat:  int = stats.matched_donations if stats is not None else 0;
    s_vol:  int = stats.volunteers_available if stats is not None else 0;
    s_kg:   int = stats.total_kg_rescued if stats is not None else 0;

    dr_disp: int       = dispatch_result.dispatched if dispatch_result is not None else 0;
    dr_skip: int       = dispatch_result.skipped if dispatch_result is not None else 0;
    dr_log:  list[str] = dispatch_result.log if dispatch_result is not None else [];

    return (
        <div className="nourish-page">

            <div className="nourish-header">
                <div className="nourish-header-inner">
                    <div className="flex items-center gap-2.5">
                        <div className="w-7 h-7 bg-primary rounded flex items-center justify-center flex-shrink-0">
                            <Leaf size={14} color="white" strokeWidth={2.5} />
                        </div>
                        <span className="text-base font-bold text-foreground tracking-tight">{"Nourish"}</span>
                        <span className="text-xs text-muted-foreground hidden md:block">{"Food Rescue Dispatcher"}</span>
                    </div>
                    <div className="flex items-center gap-2">
                        <button className="btn btn-ghost gap-1.5 text-xs" onClick={handle_reset} disabled={loading}>
                            <RefreshCw size={13} />
                            {"Reset"}
                        </button>
                        <button className="btn btn-ghost gap-1.5 text-xs" onClick={handle_logout}>
                            <LogOut size={13} />
                            {"Sign out"}
                        </button>
                    </div>
                </div>
            </div>

            <div className="nourish-main">
                {error and <div className="error-box mb-5">{error}</div>}

                <div className="stats-grid">
                    <div className="stat-card">
                        <div className="stat-card-icon"><Building2 size={16} strokeWidth={1.5} /></div>
                        <div className="stat-card-label">{"Businesses"}</div>
                        <div className="stat-card-value">{str(s_biz)}</div>
                    </div>
                    <div className="stat-card">
                        <div className="stat-card-icon"><Home size={16} strokeWidth={1.5} /></div>
                        <div className="stat-card-label">{"Shelters"}</div>
                        <div className="stat-card-value">{str(s_sh)}</div>
                    </div>
                    <div className="stat-card stat-card-red">
                        <div className="stat-card-icon"><Package size={16} strokeWidth={1.5} /></div>
                        <div className="stat-card-label">{"Pending"}</div>
                        <div className="stat-card-value">{str(s_pend)}</div>
                    </div>
                    <div className="stat-card stat-card-green">
                        <div className="stat-card-icon"><CheckCircle2 size={16} strokeWidth={1.5} /></div>
                        <div className="stat-card-label">{"Matched"}</div>
                        <div className="stat-card-value">{str(s_mat)}</div>
                    </div>
                    <div className="stat-card">
                        <div className="stat-card-icon"><Truck size={16} strokeWidth={1.5} /></div>
                        <div className="stat-card-label">{"Volunteers"}</div>
                        <div className="stat-card-value">{str(s_vol)}</div>
                    </div>
                    <div className="stat-card stat-card-green">
                        <div className="stat-card-icon"><Scale size={16} strokeWidth={1.5} /></div>
                        <div className="stat-card-label">{"Rescued"}</div>
                        <div className="stat-card-value">{str(s_kg) + "kg"}</div>
                    </div>
                </div>

                <div className="action-bar">
                    <button
                        className="btn btn-primary gap-2"
                        onClick={handle_start_dispatch}
                        disabled={dispatching or loading}
                    >
                        {dispatching and <span className="dispatch-spinner" />}
                        {not dispatching and <Play size={14} />}
                        {"Running Dispatch..." if dispatching else "Run Dispatch Cycle"}
                    </button>
                    <button className="btn gap-2" onClick={open_modal}>
                        <Plus size={14} />
                        {"Add Donation"}
                    </button>
                </div>

                <div className="dashboard-grid">
                    <div className="flex flex-col gap-4">
                        <div className="panel">
                            <div className="panel-header">
                                <span className="panel-title">
                                    <Package size={14} strokeWidth={1.5} />
                                    {"Donations"}
                                </span>
                                <span className="panel-count">{str(len(donations))}</span>
                            </div>
                            {loading and <div className="empty-state">{"Loading..."}</div>}
                            {not loading and len(donations) == 0 and
                                <div className="empty-state">{"No donations yet. Add one to get started."}</div>
                            }
                            {not loading and len(donations) > 0 and
                                <div className="donation-list">
                                    {[<div key={donations[i].id} className="donation-row">
                                        <div className="flex flex-col min-w-0">
                                            <span className="donation-food">{donations[i].food_type}</span>
                                            <span className="donation-meta">
                                                {str(donations[i].quantity) + " kg  ·  " + donations[i].business_name}
                                            </span>
                                            {donations[i].shelter_name and
                                                <span className="donation-route">
                                                    {"Allocated to " + donations[i].shelter_name}
                                                </span>
                                            }
                                            {donations[i].volunteer_name and
                                                <span className="donation-volunteer">
                                                    {"Courier: " + donations[i].volunteer_name}
                                                </span>
                                            }
                                        </div>
                                        <span className={badge_cls(donations[i].status)}>
                                            {badge_lbl(donations[i].status)}
                                        </span>
                                    </div>
                                    for i in range(len(donations))]}
                                </div>
                            }
                        </div>

                        <div className="system-log">
                            <div className="system-log-header">
                                <span className="panel-title">
                                    <Terminal size={14} strokeWidth={1.5} />
                                    {"System Log"}
                                </span>
                                {dispatch_result is not None and
                                    <span className="text-xs text-muted-foreground">
                                        {str(dr_disp) + " dispatched · " + str(dr_skip) + " skipped"}
                                    </span>
                                }
                            </div>
                            <div className="system-log-body">
                                {len(log_lines) == 0 and not dispatching and len(dr_log) == 0 and
                                    <span className="text-muted-foreground">{"Awaiting dispatch cycle..."}</span>
                                }
                                {[<div key={str(i)} className={"log-line " + ("log-line-active" if i == len(log_lines) - 1 else "")}>
                                    {log_lines[i]}
                                    {i == len(log_lines) - 1 and dispatching and <span className="log-cursor" />}
                                </div>
                                for i in range(len(log_lines))]}
                                {not dispatching and len(dr_log) > 0 and
                                    <div>
                                        {[<div key={"r" + str(i)} className="log-line">{dr_log[i]}</div>
                                          for i in range(len(dr_log))]}
                                        <div className="log-line log-line-active">{"[System] Dispatch cycle complete."}</div>
                                    </div>
                                }
                            </div>
                        </div>
                    </div>

                    <div className="flex flex-col gap-4">
                        <div className="panel">
                            <div className="panel-header">
                                <span className="panel-title">
                                    <Home size={14} strokeWidth={1.5} />
                                    {"Shelter Capacity"}
                                </span>
                            </div>
                            {loading and <div className="empty-state">{"Loading..."}</div>}
                            {not loading and
                                <div className="shelter-list">
                                    {[<div key={shelters[i].id} className="shelter-row">
                                        <div className="shelter-name">{shelters[i].name}</div>
                                        <div className="shelter-location">{shelters[i].location}</div>
                                        <div className="capacity-bar-wrap">
                                            <div className="capacity-bar">
                                                <div
                                                    className="capacity-fill"
                                                    style={{"width": str(shelters[i].pct_full) + "%"}}
                                                />
                                            </div>
                                            <span className="capacity-label">
                                                {str(shelters[i].current_capacity) + " / " + str(shelters[i].max_capacity) + " kg"}
                                            </span>
                                        </div>
                                        <div className="need-tags">
                                            {[<span key={str(j)} className="need-tag">{shelters[i].needed_items[j]}</span>
                                              for j in range(len(shelters[i].needed_items))]}
                                        </div>
                                    </div>
                                    for i in range(len(shelters))]}
                                </div>
                            }
                        </div>

                        <div className="panel">
                            <div className="panel-header">
                                <span className="panel-title">
                                    <Truck size={14} strokeWidth={1.5} />
                                    {"Volunteers"}
                                </span>
                                <span className="panel-count">{str(len(volunteers))}</span>
                            </div>
                            {loading and <div className="empty-state">{"Loading..."}</div>}
                            {not loading and len(volunteers) == 0 and
                                <div className="empty-state">{"No volunteers registered."}</div>
                            }
                            {not loading and len(volunteers) > 0 and
                                <div className="volunteer-list">
                                    {[<div key={volunteers[i].id} className="volunteer-row">
                                        <div className="flex flex-col">
                                            <span className="volunteer-name">{volunteers[i].name}</span>
                                            <span className="volunteer-meta">
                                                {volunteers[i].vehicle_type + "  ·  " + volunteers[i].location}
                                            </span>
                                        </div>
                                        <span className={"badge-available" if volunteers[i].is_available else "badge-dispatched"}>
                                            {"Available" if volunteers[i].is_available else "Dispatched"}
                                        </span>
                                    </div>
                                    for i in range(len(volunteers))]}
                                </div>
                            }
                        </div>
                    </div>
                </div>
            </div>

            {show_modal and
                <div className="modal-overlay" onClick={close_modal}>
                    <div className="modal-box" onClick={lambda(e: MouseEvent) -> None { e.stopPropagation(); }}>
                        <div className="modal-header">
                            <span className="modal-title">{"Register Donation"}</span>
                            <button className="btn btn-ghost p-1.5" onClick={close_modal}>
                                <X size={16} />
                            </button>
                        </div>
                        <form onSubmit={handle_add}>
                            <div className="modal-body">
                                <div>
                                    <label className="label">{"Source Business"}</label>
                                    <select className="select" value={form_biz} onChange={handle_biz} required={True}>
                                        <option value="FreshMart Supermarket">{"FreshMart Supermarket"}</option>
                                        <option value="The Green Bistro">{"The Green Bistro"}</option>
                                        <option value="City Bakery">{"City Bakery"}</option>
                                        <option value="Metro Deli">{"Metro Deli"}</option>
                                    </select>
                                </div>
                                <div>
                                    <label className="label">{"Food Type"}</label>
                                    <select className="select" value={form_food} onChange={handle_food} required={True}>
                                        <option value="vegetables">{"Vegetables"}</option>
                                        <option value="bread">{"Bread"}</option>
                                        <option value="dairy">{"Dairy"}</option>
                                        <option value="canned goods">{"Canned Goods"}</option>
                                        <option value="rice">{"Rice"}</option>
                                        <option value="prepared meals">{"Prepared Meals"}</option>
                                    </select>
                                </div>
                                <div>
                                    <label className="label">{"Weight (kg)"}</label>
                                    <input
                                        className="input"
                                        type="number"
                                        min="1"
                                        placeholder="e.g. 25"
                                        value={form_qty}
                                        onChange={handle_qty}
                                        required={True}
                                    />
                                </div>
                                <div>
                                    <label className="label">{"Expiration Window"}</label>
                                    <select className="select" value={form_expiry} onChange={handle_expiry}>
                                        <option value="2099-12-31T18:00:00">{"Valid (long shelf life)"}</option>
                                        <option value="2025-12-31T18:00:00">{"Expires end of year"}</option>
                                        <option value="2025-07-01T18:00:00">{"Expires in 3 months"}</option>
                                        <option value="2000-01-01T00:00:00">{"Already expired (test)"}</option>
                                    </select>
                                </div>
                                {form_error and <div className="error-box">{form_error}</div>}
                            </div>
                            <div className="modal-footer">
                                <button className="btn" type="button" onClick={close_modal}>{"Cancel"}</button>
                                <button className="btn btn-primary" type="submit" disabled={form_loading}>
                                    {"Adding..." if form_loading else "Add Donation"}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            }
        </div>
    );
}
