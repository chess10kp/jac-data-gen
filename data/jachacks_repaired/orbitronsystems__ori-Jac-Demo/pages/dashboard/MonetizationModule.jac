def:pub MonetizationModule() -> JsxElement {
    has active_tab: str = "revenue";

    def set_revenue(e: MouseEvent) -> None { active_tab = "revenue"; }
    def set_costs(e: MouseEvent) -> None { active_tab = "costs"; }
    def set_billing(e: MouseEvent) -> None { active_tab = "billing"; }

    revenue_streams = [
        {"name": "Freight Contracts", "amount": "$1,240,000", "pct": 43.7, "change": "+12.4%", "up": True},
        {"name": "Last-Mile Delivery", "amount": "$820,000", "pct": 28.9, "change": "+28.1%", "up": True},
        {"name": "Cold Chain Logistics", "amount": "$480,000", "pct": 16.9, "change": "+5.2%", "up": True},
        {"name": "Express Services", "amount": "$200,000", "pct": 7.0, "change": "-2.1%", "up": False},
        {"name": "Other Services", "amount": "$100,000", "pct": 3.5, "change": "+1.8%", "up": True},
    ];

    cost_breakdown = [
        {"name": "Fuel", "amount": "$284,000", "pct": 23.5, "icon": "⛽"},
        {"name": "Driver Wages", "amount": "$420,000", "pct": 34.7, "icon": "👤"},
        {"name": "Maintenance", "amount": "$156,000", "pct": 12.9, "icon": "🔧"},
        {"name": "Insurance", "amount": "$98,000", "pct": 8.1, "icon": "🛡️"},
        {"name": "Tolls & Permits", "amount": "$67,000", "pct": 5.5, "icon": "🛣️"},
        {"name": "Admin & Overhead", "amount": "$185,000", "pct": 15.3, "icon": "🏢"},
    ];

    invoices = [
        {"id": "INV-2024-0847", "client": "Apex Retail Corp", "amount": "$48,200", "due": "Dec 30", "status": "pending"},
        {"id": "INV-2024-0846", "client": "Metro Distribution", "amount": "$32,100", "due": "Dec 28", "status": "paid"},
        {"id": "INV-2024-0845", "client": "FreshChain Foods", "amount": "$21,500", "due": "Dec 25", "status": "overdue"},
        {"id": "INV-2024-0844", "client": "BuildRight Supplies", "amount": "$15,800", "due": "Dec 22", "status": "paid"},
        {"id": "INV-2024-0843", "client": "TechParts Global", "amount": "$9,400", "due": "Dec 20", "status": "paid"},
    ];

    def get_invoice_badge(s: str) -> str {
        if s == "paid" { return "badge-success"; }
        if s == "overdue" { return "badge-danger"; }
        return "badge-warning";
    }

    return (
        <div>
            <div className="module-header">
                <div className="flex items-center justify-between">
                    <div>
                        <h1 className="module-title">💰 Monetization</h1>
                        <p className="module-subtitle">Revenue tracking, cost analysis, and billing management</p>
                    </div>
                    <button className="btn btn-primary">+ New Invoice</button>
                </div>
            </div>

            <div className="stats-grid-4 mb-6">
                <div className="stat-card">
                    <div className="stat-label">Monthly Revenue</div>
                    <div className="stat-value text-emerald-400">$2.84M</div>
                    <div className="stat-change up">↑ 14.2% vs last month</div>
                </div>
                <div className="stat-card">
                    <div className="stat-label">Operating Costs</div>
                    <div className="stat-value text-red-400">$1.21M</div>
                    <div className="stat-change up">↓ 3.8% reduction</div>
                </div>
                <div className="stat-card">
                    <div className="stat-label">Net Profit</div>
                    <div className="stat-value text-primary">$1.63M</div>
                    <div className="stat-change up">↑ 57.4% margin</div>
                </div>
                <div className="stat-card">
                    <div className="stat-label">Outstanding</div>
                    <div className="stat-value text-amber-400">$69.7K</div>
                    <div className="stat-change">3 invoices pending</div>
                </div>
            </div>

            <div className="flex gap-1 border border-border rounded-lg p-1 mb-5 w-fit">
                <button className={"btn btn-ghost px-4 py-2 text-sm " + ("bg-muted text-foreground" if active_tab == "revenue" else "")} onClick={set_revenue}>💰 Revenue Streams</button>
                <button className={"btn btn-ghost px-4 py-2 text-sm " + ("bg-muted text-foreground" if active_tab == "costs" else "")} onClick={set_costs}>📉 Cost Breakdown</button>
                <button className={"btn btn-ghost px-4 py-2 text-sm " + ("bg-muted text-foreground" if active_tab == "billing" else "")} onClick={set_billing}>🧾 Billing</button>
            </div>

            {active_tab == "revenue" and (
                <div className="grid grid-cols-2 gap-4">
                    <div className="card overflow-hidden">
                        <div className="px-5 py-4 border-b border-border text-sm font-bold text-foreground">Revenue by Stream</div>
                        <div className="flex flex-col">
                            {[
                                <div key={str(i)} className="px-5 py-4 border-b border-border last:border-b-0">
                                    <div className="flex items-center justify-between mb-2">
                                        <div className="text-sm font-medium text-foreground">{revenue_streams[i]["name"]}</div>
                                        <div className="flex items-center gap-2">
                                            <span className={"text-xs font-bold " + ("text-emerald-400" if revenue_streams[i]["up"] else "text-red-400")}>{revenue_streams[i]["change"]}</span>
                                            <span className="text-sm font-bold text-foreground">{revenue_streams[i]["amount"]}</span>
                                        </div>
                                    </div>
                                    <div className="flex items-center gap-2">
                                        <div className="progress-bar flex-1">
                                            <div className="progress-fill" style={{"width": str(int(revenue_streams[i]["pct"])) + "%"}}></div>
                                        </div>
                                        <span className="text-xs text-muted-foreground w-10 text-right">{str(int(revenue_streams[i]["pct"]))}%</span>
                                    </div>
                                </div>
                                for i in range(len(revenue_streams))
                            ]}
                        </div>
                    </div>

                    <div className="card p-5">
                        <div className="text-sm font-bold text-foreground mb-4">Revenue Trend (12 months)</div>
                        <div className="flex items-end gap-1.5 h-40 mb-2">
                            {[
                                <div
                                    key={str(i)}
                                    className="flex-1 rounded-t-sm"
                                    style={{"height": str(40 + i * 5) + "%", "background": "linear-gradient(180deg, #10b981 0%, rgba(16,185,129,0.3) 100%)"}}
                                ></div>
                                for i in range(12)
                            ]}
                        </div>
                        <div className="flex justify-between text-xs text-muted-foreground">
                            <span>Jan</span><span>Mar</span><span>May</span><span>Jul</span><span>Sep</span><span>Nov</span>
                        </div>
                        <div className="mt-4 p-3 rounded-lg bg-muted">
                            <div className="text-xs text-muted-foreground">YTD Revenue</div>
                            <div className="text-xl font-black text-emerald-400">$28.4M</div>
                            <div className="text-xs text-emerald-400">↑ 22.7% vs last year</div>
                        </div>
                    </div>
                </div>
            )}

            {active_tab == "costs" and (
                <div className="grid grid-cols-2 gap-4">
                    {[
                        <div key={str(i)} className="card p-5">
                            <div className="flex items-center gap-3 mb-3">
                                <div className="text-2xl">{cost_breakdown[i]["icon"]}</div>
                                <div>
                                    <div className="text-sm font-bold text-foreground">{cost_breakdown[i]["name"]}</div>
                                    <div className="text-lg font-black text-foreground">{cost_breakdown[i]["amount"]}</div>
                                </div>
                            </div>
                            <div className="flex items-center gap-2">
                                <div className="progress-bar flex-1">
                                    <div className="progress-fill" style={{"width": str(int(cost_breakdown[i]["pct"])) + "%"}}></div>
                                </div>
                                <span className="text-xs text-muted-foreground">{str(int(cost_breakdown[i]["pct"]))}%</span>
                            </div>
                        </div>
                        for i in range(len(cost_breakdown))
                    ]}
                </div>
            )}

            {active_tab == "billing" and (
                <div className="card overflow-hidden">
                    <div className="px-5 py-4 border-b border-border text-sm font-bold text-foreground">Recent Invoices</div>
                    <table className="data-table">
                        <thead>
                            <tr>
                                <th>Invoice ID</th>
                                <th>Client</th>
                                <th>Amount</th>
                                <th>Due Date</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {[
                                <tr key={str(i)}>
                                    <td className="font-mono text-xs text-primary">{invoices[i]["id"]}</td>
                                    <td className="font-medium">{invoices[i]["client"]}</td>
                                    <td className="font-bold text-foreground">{invoices[i]["amount"]}</td>
                                    <td className="text-sm text-muted-foreground">{invoices[i]["due"]}</td>
                                    <td><span className={"badge " + get_invoice_badge(str(invoices[i]["status"]))}>{invoices[i]["status"]}</span></td>
                                    <td>
                                        <div className="flex gap-1">
                                            <button className="btn btn-ghost px-2 py-1 text-xs">View</button>
                                            <button className="btn btn-ghost px-2 py-1 text-xs">Send</button>
                                        </div>
                                    </td>
                                </tr>
                                for i in range(len(invoices))
                            ]}
                        </tbody>
                    </table>
                </div>
            )}
        </div>
    );
}
