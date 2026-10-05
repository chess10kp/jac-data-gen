"""frontend.cl.jac - Dashboard with GlobalFabric in Sidebar"""

import "./styles.css";

import from main {
    setup_graph,
    handle_user_input,
    fetch_client_audit,
    fetch_news,
    fetch_live_api_news,
    fetch_emails,
    fetch_map_entities,
    fetch_growth_data,
    fetch_calendar,
    fetch_detailed_transactions,
    run_business_agent,
    run_opportunity_agent,
    run_risk_agent,
    run_data_agent,
    run_b2b_matchmaker,
    connect_global_node,
    disconnect_global_node,
    run_morning_briefing,
    handle_user_chat
}

def:pub app -> JsxElement {
    has chat_input: str = "",
        chat_history: list = [],
        loading_agent: bool = False,
        suggestions: list = [],
        emails: list = [],
        map_entities: list = [],
        growth_data: list = [],
        calendar_events: list = [],
        detailed_tx_data: list = [],
        selected_name: str = "None",
        selected_node: dict = {},
        active_page: str = "dashboard",

        connecting_fabric: bool = False,
        
        # Unified Active Monitor State
        latest_run_type: str = "",
        latest_run_summary: str = "",
        latest_run_thoughts: list = [],
        
        # Running Locks
        running_analyst: bool = False,
        running_opp: bool = False,
        running_risk: bool = False,
        running_data: bool = False,
        
        # Inputs
        risk_input: str = "",
        data_input: str = "",
        fetching_news: bool = False,
        
        # --- NEW: GlobalFabric States ---
        global_fabric_on: bool = False,
        problem_input: str = "",
        my_problems: list = [],
        running_b2b: bool = False,

        # --- Morning Briefing States ---
        daily_tasks: str = "",
        boot_thoughts: list = [],
        loading_boot: bool = True,
        
        # History State
        agent_history: list = [],
        viewing_history_item: dict = {};

    async def initialize_dashboard;
    async def handle_ask_agent;
    async def run_manual_audit;
    async def run_live_news_fetch;
    async def trigger_agent_analysis;
    async def trigger_opp_analysis;
    async def trigger_risk_analysis;
    async def trigger_data_analysis;
    def handle_keypress(e: KeyboardEvent);
    
    # New GlobalFabric Methods
    async def trigger_add_problem;
    async def trigger_b2b_match;
    async def toggle_global_fabric;
    def handle_problem_keypress(e: KeyboardEvent);

    async can with entry {
        await initialize_dashboard();
    }

    # ==========================================
    # POP-OUT PAGES
    # ==========================================

    if active_page == "news" {
        return <div class="news-page-container"><div class="news-header"><h2>Live Industry News</h2><div class="news-buttons"><button class="action-btn" onClick={run_live_news_fetch} disabled={fetching_news}>{("Fetching..." if fetching_news else "Fetch Live API News")}</button><button class="secondary-btn" onClick={lambda { active_page = "dashboard"; }}>← Back</button></div></div><div class="news-list">{[ <div key={s} class="news-item"><p>{s}</p></div> for s in suggestions ]}</div></div>;
    }

    if active_page == "details" {
        return <div class="news-page-container full-map-view">
            <div class="news-header">
                <h2>Supply Network: {selected_name}</h2>
                <button class="secondary-btn" onClick={lambda { active_page = "dashboard"; }}>← Back to Dashboard</button>
            </div>
            
            <div style={{"display": "flex", "gap": "20px", "fontSize": "14px", "marginBottom": "15px", "fontWeight": "bold", "justifyContent": "center", "background": "#f8fafc", "padding": "10px", "borderRadius": "8px", "border": "1px solid #e2e8f0"}}>
                <span style={{"color": "#ef4444"}}>🔴 Issues</span>
                <span style={{"color": "#10b981"}}>🟢 Suppliers</span>
                <span style={{"color": "#3b82f6"}}>🔵 Clients</span>
                <span style={{"color": "#334155"}}>⚫ Network Match</span>
            </div>

            <div class="map-canvas-large" style={{"height": "500px", "background": "url('/assets/file.svg')", "backgroundSize": "cover", "position": "relative", "borderRadius": "12px", "border": "2px solid #cbd5e1", "boxShadow": "inset 0 2px 4px rgba(0,0,0,0.05)"}}>
                {[ 
                    <div key={e["name"]} 
                        class="map-pin" 
                        style={{"backgroundColor": e["status"], "left": e["x"], "top": e["y"]}} 
                        onClick={lambda { selected_name = e["name"]; selected_node = e; }}>
                    </div> 
                for e in map_entities]}
            </div>
            
            {(
                <div class="details-card" style={{"marginTop": "20px", "padding": "25px", "background": "#ffffff", "borderRadius": "12px", "border": "1px solid #e2e8f0", "boxShadow": "0 4px 6px -1px rgba(0, 0, 0, 0.1)"}}>
                    <div style={{"display": "flex", "justifyContent": "space-between", "alignItems": "center", "marginBottom": "20px", "borderBottom": "1px solid #cbd5e1", "paddingBottom": "15px"}}>
                        <h3 style={{"margin": "0", "fontSize": "22px", "color": "#1e293b"}}>{selected_name}</h3>
                        
                        <span style={{"padding": "6px 12px", "borderRadius": "20px", "fontSize": "13px", "fontWeight": "bold", "color": "white", "backgroundColor": ("#ef4444" if selected_node["status"] == "red" else ("#10b981" if selected_node["status"] == "green" else ("#334155" if selected_node["status"] == "black" else "#3b82f6")))}}>
                            {("Issue Detected" if selected_node["status"] == "red" else ("Active Supplier" if selected_node["status"] == "green" else ("GlobalFabric Match" if selected_node["status"] == "black" else "Active Client")))}
                        </span>
                    </div>
                    
                    <div style={{"display": "flex", "gap": "20px", "marginBottom": "20px", "alignItems": "center"}}>
                        <div style={{"flex": "2", "fontSize": "15px", "color": "#475569"}}>
                            <p style={{"margin": "0 0 10px 0"}}><strong>📞 Phone:</strong> {selected_node.get("phone", "555-0199")}</p>
                            <p style={{"margin": "0"}}><strong>✉️ Email:</strong> {selected_node.get("email", "contact@company.com")}</p>
                        </div>
                        <div style={{"flex": "1"}}>
                            <a href={"mailto:" + selected_node.get("email", "contact@company.com") + "?subject=Connecting via GlobalFabric&body=Hi, I am reaching out regarding..."} 
                               style={{"display": "inline-block", "width": "100%", "textAlign": "center", "background": ("#334155" if selected_node["status"] == "black" else "#3b82f6"), "color": "white", "padding": "12px", "borderRadius": "8px", "textDecoration": "none", "fontSize": "15px", "fontWeight": "bold", "boxSizing": "border-box", "boxShadow": "0 2px 4px rgba(0,0,0,0.1)"}}>
                                Send Email
                            </a>
                        </div>
                    </div>

                    {(
                        <div style={{"background": "#fef2f2", "padding": "15px", "borderRadius": "8px", "border": "1px solid #fca5a5"}}>
                            <strong style={{"color": "#f24545", "fontSize": "14px"}}>🚨 Operational Alert:</strong>
                            <p style={{"color": "#ef3b3b", "fontSize": "14px", "margin": "5px 0 0 0"}}>Supply chain variance detected. Immediate contact recommended to resolve fulfillment issues.</p>
                        </div>
                    ) if selected_node["status"] == "red" else None}
                    
                    {(
                        <div style={{"background": "#f8fafc", "padding": "15px", "borderRadius": "8px", "border": "1px solid #cbd5e1"}}>
                            <strong style={{"color": "#334155", "fontSize": "14px"}}>🌐 Network Match Notes:</strong>
                            <p style={{"color": "#475569", "fontSize": "14px", "margin": "5px 0 0 0"}}>This entity was surfaced by the B2B Matchmaker. Reference your broadcasted problems when reaching out.</p>
                        </div>
                    ) if selected_node["status"] == "black" else None}
                </div>
            ) if selected_name != "None" else None}
        </div>;
    }

    if active_page == "transactions" {
        return <div class="news-page-container"><div class="news-header"><h2>Company Financial Ledger</h2><button class="secondary-btn" onClick={lambda { active_page = "dashboard"; }}>← Back</button></div><div class="ledger-list" style={{"marginTop": "20px"}}>{[ <div key={m["month"]} style={{"background": "#fff", "padding": "15px", "borderRadius": "8px", "marginBottom": "15px", "border": "1px solid #e2e8f0"}}><h3 style={{"borderBottom": "2px solid #3b82f6", "paddingBottom": "5px", "marginTop": "0"}}>{m["month"]} Ledger - Total: ${str(m["total"])}</h3><table style={{"width": "100%", "marginTop": "10px", "fontSize": "14px", "textAlign": "left", "borderCollapse": "collapse"}}><thead><tr style={{"color": "#64748b", "borderBottom": "1px solid #e2e8f0"}}><th style={{"padding": "8px 4px"}}>Date</th><th style={{"padding": "8px 4px"}}>Item Description</th><th style={{"padding": "8px 4px"}}>Amount</th></tr></thead><tbody>{[ <tr key={s["date"] + s["item"]} style={{"borderBottom": "1px solid #f1f5f9"}}><td style={{"padding": "8px 4px"}}>{s["date"]}</td><td style={{"padding": "8px 4px"}}>{s["item"]}</td><td style={{"padding": "8px 4px"}}>${str(s["amount"])}</td></tr> for s in m["sales"]]}</tbody></table></div> for m in detailed_tx_data]}</div></div>;
    }

    if active_page == "thinking" {
        return <div class="news-page-container"><div class="news-header"><h2>{latest_run_type} - Live Log</h2><button class="secondary-btn" onClick={lambda { active_page = "dashboard"; }}>← Back to Dashboard</button></div><div style={{"background": "#1e293b", "color": "#10b981", "padding": "20px", "borderRadius": "8px", "fontFamily": "monospace", "marginTop": "20px", "lineHeight": "1.6", "maxHeight": "600px", "overflowY": "auto"}}>{[ <div key={thought}>{">"} {thought}</div> for thought in latest_run_thoughts ]}<div style={{"color": "#cbd5e1", "marginTop": "20px"}}>{">"} PROCESS COMPLETED.</div></div></div>;
    }

    if active_page == "agent_history" {
        return <div class="news-page-container" style={{"padding": "30px"}}><div class="news-header" style={{"marginBottom": "20px"}}><h2>Agent Session History</h2><button class="secondary-btn" onClick={lambda { active_page = "dashboard"; }}>← Back to Dashboard</button></div>{(<p style={{"color": "#64748b"}}>No agents run yet in this session.</p>) if len(agent_history) == 0 else None}<div style={{"display": "grid", "gridTemplateColumns": "1fr 1fr", "gap": "20px"}}>{[ <div key={item["type"] + str(item["thoughts"])} style={{"background": "#fff", "padding": "20px", "borderRadius": "12px", "border": "1px solid #e2e8f0", "boxShadow": "0 2px 4px rgba(0,0,0,0.05)", "display": "flex", "flexDirection": "column", "justifyContent": "space-between"}}><div><h3 style={{"margin": "0 0 10px 0", "color": "#334155", "borderBottom": "1px solid #f1f5f9", "paddingBottom": "10px"}}>{item["type"]}</h3><p style={{"fontSize": "14px", "color": "#475569", "lineHeight": "1.6", "maxHeight": "150px", "overflowY": "auto"}}>{item["summary"]}</p></div><button class="small-btn" style={{"background": "#475569", "color": "white", "marginTop": "15px", "alignSelf": "flex-start"}} onClick={lambda { viewing_history_item = item; active_page = "history_thinking"; }}>Show Thinking Log</button></div> for item in agent_history]}</div></div>;
    }

    if active_page == "history_thinking" {
        return <div class="news-page-container"><div class="news-header"><h2>{viewing_history_item["type"]} - Archived Log</h2><button class="secondary-btn" onClick={lambda { active_page = "agent_history"; }}>← Back to History</button></div><div style={{"background": "#1e293b", "color": "#cbd5e1", "padding": "20px", "borderRadius": "8px", "fontFamily": "monospace", "marginTop": "20px", "lineHeight": "1.6", "maxHeight": "600px", "overflowY": "auto"}}>{[ <div key={thought}>{">"} {thought}</div> for thought in viewing_history_item["thoughts"] ]}</div></div>;
    }

    # ==========================================
    # MAIN DASHBOARD 
    # ==========================================

    return
        <div class="dashboard-container">





            <div class="agent-sidebar">
                <div style={{"display": "flex", "justifyContent": "space-between", "alignItems": "center", "marginBottom": "15px"}}>
                    <h2 style={{"margin": "0"}}>JacFabric Agent</h2>
                    <button class="small-btn" style={{"background": "#e2e8f0", "color": "#334155"}} onClick={lambda { active_page = "agent_history"; }}>View History</button>
                </div>
                
                <div style={{"background": "#f8fafc", "padding": "15px", "borderRadius": "8px", "marginBottom": "15px", "border": "1px solid #e2e8f0"}}>
                    
                    <button class="action-btn" style={{"width": "100%", "marginBottom": "10px", "background": "#3b82f6"}} onClick={trigger_agent_analysis} disabled={running_analyst}>
                        {("Analyzing Graph..." if running_analyst else "📊 Run Business Analysis")}
                    </button>

                    <button class="action-btn" style={{"width": "100%", "marginBottom": "10px", "background": "#f59e0b"}} onClick={trigger_opp_analysis} disabled={running_opp}>
                        {("Hunting..." if running_opp else "🎯 Find Opportunities")}
                    </button>

                    <div style={{"display": "flex", "gap": "5px", "marginBottom": "10px"}}>
                        <input value={risk_input} onChange={lambda (e: ChangeEvent) { risk_input = e.target.value; }} placeholder="Proposed decision..." style={{"flex": "1", "padding": "8px", "borderRadius": "6px", "border": "1px solid #cbd5e1"}} />
                        <button class="action-btn" style={{"background": "#ef4444", "padding": "8px 12px"}} onClick={trigger_risk_analysis} disabled={running_risk}>
                            {("..." if running_risk else "🛡️ Risk")}
                        </button>
                    </div>

                    <div style={{"display": "flex", "gap": "5px"}}>
                        <input value={data_input} onChange={lambda (e: ChangeEvent) { data_input = e.target.value; }} placeholder="Data command..." style={{"flex": "1", "padding": "8px", "borderRadius": "6px", "border": "1px solid #cbd5e1"}} />
                        <button class="action-btn" style={{"background": "#a855f7", "padding": "8px 12px"}} onClick={trigger_data_analysis} disabled={running_data}>
                            {("..." if running_data else "🛠️ Execute")}
                        </button>
                    </div>

                    <hr style={{"border": "none", "borderTop": "1px solid #cbd5e1", "margin": "15px 0"}}/>

                    <div style={{"display": "flex", "justifyContent": "space-between", "alignItems": "center", "marginBottom": "10px"}}>
                        <strong style={{"color": "#334155", "fontSize": "14px"}}>🌐 GlobalFabric</strong>
                        <button class="small-btn" style={{"background": ("#ef4444" if global_fabric_on else "#10b981"), "color": "white", "fontSize": "11px", "padding": "4px 8px"}} onClick={toggle_global_fabric} disabled={connecting_fabric}>
                            {("Connecting..." if connecting_fabric else ("Disconnect" if global_fabric_on else "Join Node"))}
                        </button>
                    </div>

                    {(
                        <div>
                            <div style={{"display": "flex", "gap": "5px", "marginBottom": "10px"}}>
                                <input value={problem_input} onChange={lambda (e: ChangeEvent) { problem_input = e.target.value; }} onKeyPress={handle_problem_keypress} placeholder="Enter a business problem..." style={{"flex": "1", "padding": "8px", "borderRadius": "6px", "border": "1px solid #cbd5e1", "fontSize": "12px"}} />
                                <button class="action-btn" style={{"background": "#64748b", "padding": "8px 12px", "fontSize": "12px"}} onClick={trigger_add_problem}>Add</button>
                            </div>
                            
                            {(
                                <div style={{"maxHeight": "120px", "overflowY": "auto", "marginBottom": "10px", "border": "1px solid #e2e8f0", "borderRadius": "6px", "padding": "4px", "background": "#ffffff"}}>
                                    {[ 
                                        <div key={p} style={{"fontSize": "12px", "background": "#f1f5f9", "padding": "6px 8px", "borderRadius": "4px", "marginBottom": "4px", "display": "flex", "justifyContent": "space-between", "alignItems": "center", "color": "#334155"}}>
                                            <span style={{"flex": "1", "marginRight": "10px"}}>{p}</span>
                                            <span style={{"color": "#10b981", "fontSize": "10px", "fontWeight": "bold", "whiteSpace": "nowrap"}}>Broadcasted ✓</span>
                                        </div> 
                                    for p in my_problems ]}
                                </div>
                            ) if len(my_problems) > 0 else None}

                            <button class="action-btn" style={{"width": "100%", "background": "#10b981"}} onClick={trigger_b2b_match} disabled={running_b2b or len(my_problems) == 0}>
                                {("Scanning Network..." if running_b2b else "Search Fabric for Matches")}
                            </button>
                        </div>
                    ) if global_fabric_on else (
                        <p style={{"fontSize": "12px", "color": "#64748b", "margin": "0", "textAlign": "center", "padding": "10px", "background": "#f1f5f9", "borderRadius": "6px"}}>Offline. Join node to broadcast problems.</p>
                    )}

                    {(
                        <div style={{"marginTop": "15px", "paddingTop": "15px", "borderTop": "1px solid #cbd5e1"}}>
                            <strong style={{"color": "#334155", "fontSize": "13px"}}>{latest_run_type} Result:</strong>
                            <p style={{"fontSize": "13px", "color": "#475569", "maxHeight": "150px", "overflowY": "auto", "background": "#ffffff", "padding": "8px", "border": "1px solid #e2e8f0", "borderRadius": "6px", "marginTop": "8px"}}>{latest_run_summary}</p>
                            <button class="small-btn" style={{"background": "#334155", "color": "white", "width": "100%", "marginTop": "8px"}} onClick={lambda { active_page = "thinking"; }}>View Processing Log</button>
                        </div>
                    ) if latest_run_summary else None}

                </div>

                <div class="chat-history" style={{"height": "150px"}}>
                    {[ <div key={len(chat_history)} class={"chat-bubble " + msg["role"]}>{msg["text"]}</div> for msg in chat_history ]}
                    {(<div class="chat-bubble agent">Thinking...</div>) if loading_agent else None}
                </div>
                <div class="chat-input-area">
                    <input value={chat_input} onChange={lambda (e: ChangeEvent) { chat_input = e.target.value; }} onKeyPress={handle_keypress} placeholder="Ask about clients..." />
                    <button onClick={handle_ask_agent} disabled={loading_agent}>Ask</button>
                </div>
            </div>













            <div class="widgets-area">
                <div class="widget maps-widget">
                    <div class="widget-header">
                        <h3>Market Map ({selected_name})</h3>
                        <button class="popout-btn" onClick={lambda { active_page = "details"; }}>Expand ↗</button>
                    </div>
                    
                    <div style={{"display": "flex", "gap": "10px", "fontSize": "11px", "marginBottom": "8px", "fontWeight": "bold", "flexWrap": "wrap"}}>
                        <span style={{"color": "#ef4444"}}>🔴 Issues</span>
                        <span style={{"color": "#10b981"}}>🟢 Suppliers</span>
                        <span style={{"color": "#3b82f6"}}>🔵 Clients</span>
                        <span style={{"color": "#334155"}}>⚫ Network Match</span>
                    </div>

                    <div class="map-canvas-small" style={{"height": "200px", "background": "url('/assets/file.svg')", "backgroundSize": "cover", "position": "relative", "borderRadius": "8px", "border": "1px solid #cbd5e1", "overflow": "hidden"}}>

                        {[ 
                            <div key={e["name"]} 
                                class="map-pin" 
                                style={{"backgroundColor": e["status"], "left": e["x"], "top": e["y"]}} 
                                onClick={lambda { selected_name = e["name"]; selected_node = e; }}>
                            </div> 
                        for e in map_entities]}
                    </div>
                    
                    {(
                        <div style={{"marginTop": "10px", "padding": "10px", "background": "#f8fafc", "border": "1px solid #e2e8f0", "borderRadius": "6px"}}>
                            
                            <p style={{"color": ("#ef4444" if selected_node["status"] == "red" else ("#35bb8f" if selected_node["status"] == "green" else ("#37619c" if selected_node["status"] == "black" else "#3b82f6"))), "fontSize": "12px", "margin": "0 0 5px 0", "fontWeight": "bold"}}>
                                {("⚠️ Issue Detected" if selected_node["status"] == "red" else ("🟢 Active Supplier" if selected_node["status"] == "green" else ("⚫ GlobalFabric Match" if selected_node["status"] == "black" else "🔵 Active Client")))}
                            </p>
                            
                            <div style={{"fontSize": "12px", "color": "#475569", "marginBottom": "8px"}}>
                                <div style={{"marginBottom": "3px"}}>📞 {selected_node.get("phone", "555-0199")}</div>
                                <div>✉️ {selected_node.get("email", "contact@company.com")}</div>
                            </div>
                            
                            <a href={"mailto:" + selected_node.get("email", "contact@company.com") + "?subject=Connecting via GlobalFabric&body=Hi, I saw your post on the network..."} 
                               style={{"display": "block", "textAlign": "center", "background": ("#334155" if selected_node["status"] == "black" else "#3b82f6"), "color": "white", "padding": "6px", "borderRadius": "4px", "textDecoration": "none", "fontSize": "12px", "fontWeight": "bold"}}>
                                Send Email
                            </a>
                        </div>
                    ) if selected_name != "None" else None}
                </div>
                
                

                <div class="widget growth-matrix" style={{"display": "flex", "flexDirection": "column", "gap": "20px", "flex": "1"}}>
                    
                    <div style={{"display": "flex", "gap": "20px", "flex": "0 0 auto"}}>
                        <div style={{"flex": "1", "borderRight": "1px solid #e2e8f0", "paddingRight": "15px"}}>
                            <h3 style={{"fontSize": "14px", "margin": "0 0 10px 0"}}>Financial Growth</h3>
                            <div style={{"display": "flex", "justifyContent": "space-between", "marginBottom": "5px"}}>
                                <p style={{"fontSize": "11px", "margin": "0"}}>Profit: $120k</p>
                                <p style={{"fontSize": "11px", "margin": "0"}}>Revenue: $450k</p>
                            </div>
                            <div style={{"height": "80px", "display": "flex", "alignItems": "flex-end", "gap": "2px", "background": "#f8fafc", "padding": "5px", "borderRadius": "4px"}}>
                                {[ <div key={g["month"]} style={{"flex": "1", "background": "#3b82f6", "height": (str(int(g["amount"]/1000)) + "%"), "borderRadius": "1px"}} title={g["month"]}></div> for g in growth_data]}
                            </div>
                            <div style={{"marginTop": "10px", "display": "flex", "gap": "5px"}}>
                                <button class="small-btn" onClick={lambda { active_page = "transactions"; }}>Transactions</button>
                                <button class="small-btn">Taxes</button>
                            </div>
                        </div>
                        
                        <div style={{"flex": "1"}}>
                            <h3 style={{"fontSize": "14px", "margin": "0 0 10px 0"}}>Calendar</h3>
                            <div class="calendar-list" style={{"maxHeight": "100px", "overflowY": "auto"}}>
                                {[ <div key={event} style={{"fontSize": "11px", "padding": "4px 0", "borderBottom": "1px solid #f1f5f9"}}>📅 {event}</div> for event in calendar_events]}
                            </div>
                            <button class="action-btn" style={{"marginTop": "10px", "width": "100%", "fontSize": "11px", "padding": "6px"}}>Sync API</button>
                        </div>
                    </div>

                    <div style={{"background": "#f8fafc", "padding": "15px", "borderRadius": "8px", "border": "1px solid #e2e8f0", "marginTop": "auto"}}>
                        <div style={{"display": "flex", "justifyContent": "space-between", "alignItems": "center", "marginBottom": "10px"}}>
                            <h3 style={{"margin": "0", "color": "#475569", "fontSize": "11px", "letterSpacing": "1px", "fontWeight": "700"}}>🌅 EXECUTIVE BRIEFING</h3>
                            
                            {(
                                <button class="small-btn" 
                                        style={{"background": "transparent", "color": "#3b82f6", "border": "none", "textDecoration": "underline", "cursor": "pointer", "padding": "0"}}
                                        onClick={lambda { latest_run_type = "🌅 Morning Briefing"; latest_run_thoughts = boot_thoughts; active_page = "thinking"; }}>
                                    View Thinking
                                </button>
                            ) if (not loading_boot and daily_tasks) else None}
                        </div>
                        
                        <div style={{"fontSize": "13px", "lineHeight": "1.6", "minHeight": "100px", "display": "flex", "flexDirection": "column", "justifyContent": "center", "color": "#1e293b"}}>
                            {(
                                <div>
                                    {[ 
                                        <div key={task} style={{"marginBottom": "6px", "display": "flex", "gap": "8px"}}>
                                            <span style={{"color": "#3b82f6", "fontWeight": "bold"}}>•</span> <span>{task.strip().replace("•", "")}</span>
                                        </div> 
                                    for task in daily_tasks.split("•") if task.strip() ]}
                                </div>
                            ) if (not loading_boot and daily_tasks) else (
                                <div style={{"color": "#94a3b8", "textAlign": "center", "fontStyle": "italic"}}>
                                    Analyzing ecosystem data...
                                </div>
                            )}
                        </div>
                    </div>              
                </div>


                
                <div class="widget graph-widget">
                    <div class="widget-header">
                        <h3>Live Knowledge Graph</h3>
                        <a href="/graph" target="_blank" class="popout-btn">Open in New Tab ↗</a>
                    </div>
                    <iframe src="/graph" class="graph-iframe" title="Jaseci Graph Viewer"></iframe>
                    <div class="graph-actions"><button class="action-btn" onClick={run_manual_audit}>Manual Client Audit</button></div>
                </div>
                
                <div class="widget suggestions-widget">
                    <div class="widget-header">
                        <h3>Alerts & Inbox</h3>
                        <button class="popout-btn" onClick={lambda { active_page = "news"; }}>News Page ↗</button>
                    </div>
                    <div class="alert-section">
                        <p class="small-label">TOP NEWS</p>
                        {[ <p key={s} class="suggestion-text">{s}</p> for s in suggestions[0:2] ]}
                    </div>
                    <div class="email-section" style={{"marginTop": "12px", "borderTop": "1px solid #f1f5f9", "paddingTop": "8px"}}>
                        <p class="small-label">PRIORITY EMAILS</p>
                        {[ <p key={e} class="suggestion-text">{e}</p> for e in emails[0:2] ]}
                    </div>
                </div>
            </div>
        </div>;
}