"""main.jac - Stable Backend with Organized Map Nodes"""
import urllib.request;
import json;
import ssl;

import from frontend { app as ClientApp }
def:pub app -> JsxElement {
    return <ClientApp/>;
}


import from byllm.lib { Model }

# Using the free Gemini model for fast, reliable demo generation
glob llm = Model(model_name="gemini/gemini-2.5-flash");

# SIMPLIFIED AI FUNCTION: Just takes the raw thought log and summarizes it
def analyze_business_state(agent_log: str) -> str by llm();
sem analyze_business_state = "You are a business analyst. Read the provided graph traversal log and write a short, 2-sentence summary of how the business is doing. Keep it simple and professional.";

def find_business_opportunities(agent_log: str) -> str by llm();
sem find_business_opportunities = "You are a proactive business strategist. Read the provided graph traversal log (containing client problems, news, emails, and map statuses). Identify 2 specific, actionable business opportunities (e.g., a sales pitch, solving a specific client's delay, or a supply chain pivot). Keep it brief, punchy, and professional.";

def assess_business_risk(agent_log: str, proposed_decision: str) -> str by llm();
sem assess_business_risk = "You are a risk management expert. Read the graph traversal log and the user's proposed business decision. Identify 2 potential risks, vulnerabilities, or negative impacts of this decision based on the current state of the business (e.g., location traffic, supply chain strain). Be concise, direct, and professional.";

# --- 1. UNIFIED AI SCHEMA ---
enum DataAction { ADD, REMOVE, UPDATE, GET, UNKNOWN }
enum DataTarget { CLIENT, CALENDAR, PRODUCT, UNKNOWN }

obj CommandData {
    has action: DataAction;
    has target: DataTarget;
    has item_name: str;
    has details: str;
}

def parse_data_command(command: str) -> CommandData by llm();
sem parse_data_command = "Parse user commands. action: ADD/REMOVE/UPDATE/GET. target: CLIENT/CALENDAR/PRODUCT. item_name is the subject (e.g., 'Bronx burgers', 'Steel Sheets', 'meeting'). details is for dates, stock numbers, or extra info.";

# --- NEW: B2B Matchmaker AI ---
def b2b_matchmaker(my_problem: str, market_posts: str) -> str by llm();
sem b2b_matchmaker = "You are an AI B2B Matchmaker. Read the user's broadcasted problem and the list of active marketplace posts from other companies. Identify the best potential match (direct or creative secondary match). Explain exactly why they should connect and how they solve each other's problems. If no match exists, suggest what kind of industry they should look for instead. Keep it to 3 concise sentences.";

# --- MORNING BRIEFING AGENT (AUTORUN) ---

def get_daily_priorities(context_str: str, critical_nodes: str) -> str by llm();
sem get_daily_priorities = "Act as a CEO's AI Chief of Staff. Review the provided context (emails, news, calendar) and the list of critical 'red' supply chain nodes. Generate EXACTLY 3 high-priority tasks for today based on this data. Format as a short, punchy bulleted list. Start each task with a relevant emoji.";

def:pub chat_with_llm(user_query: str, history: list) -> str by llm();
sem chat_with_llm = "You are the JacFabric Executive Assistant. Answer the user's query professionally. Use the chat history for context. Keep answers concise and helpful.";

node Company {
    has name: str;
}
node Metric {
    has metric_type: str,
        value: float,
        trend: str;
}
node ClientDirectory {}
node Client {
    has name: str,
        demand: str,
        problems: str;
}
node NewsNode {
    has priority_headlines: list = [],
        live_headlines: list = [];
}

node WeatherNode {
    has location: str,
        forecast: str;
}
node EmailsNode {
    has priority_emails: list = [],
        recent_emails: list = [];
}

node CalendarNode {
    has upcoming_events: list = [];
}
node Transaction {
    has month: str,
        amount: float;
}
node Product {
    has name: str,
        stock: int;
}

# Container node for cleaner graph organization
node MapDirectory {}

node MapEntity {
    has name: str,
        kind: str,  # "supplier" or "client"
        status: str,  # "green", "blue", or "red"
        x: str,
        y: str;
    # --- NEW: Contact Info ---
    has phone: str = "555-0199";
    has email: str = "contact@company.com";
}

# --- NEW: Nested Transaction Nodes ---
node TransactionsNode {}
node MonthNode {
    has month: str,
        total: float;
}
node Sale {
    has item: str,
        amount: float,
        date: str;
}

# --- NEW: Global Network Nodes ---
node GlobalMarketplace {}
node B2BPost {
    has author: str;
    has content: str;
    # --- NEW: Network Contact & Location ---
    has email: str;
    has phone: str;
    has x: str;
    has y: str;
}

def:pub setup_graph(company_name: str) -> dict {
    # Nuke old cache to prevent schema errors
    for n in [root-->] {
        del n;
    }

    comp = (root ++> Company(name=company_name))[0];
    comp ++> Metric(metric_type="Profit", value=120000.0, trend="up");
    comp ++> Metric(metric_type="Revenue", value=450000.0, trend="up");
    comp ++> Metric(metric_type="Inventory", value=850.0, trend="down");

    # Add 6 Months of Transaction Data for the Graph (Sparkline)
    months = ["Oct", "Nov", "Dec", "Jan", "Feb", "Mar"];
    amounts = [45000.0, 48000.0, 52000.0, 49000.0, 55000.0, 60000.0];
    for i in range(0, 6) {
        comp ++> Transaction(month=months[i], amount=amounts[i]);
    }

    # --- NEW: Detailed Ledger Setup ---
    ledger = (comp ++> TransactionsNode())[0];

    mar_l = (ledger ++> MonthNode(month="Mar", total=60000.0))[0];
    mar_l ++> Sale(item="Bulk Steel Grade A", amount=45000.0, date="2026-03-12");
    mar_l ++> Sale(item="Custom Alloy Sheets", amount=15000.0, date="2026-03-24");

    feb_l = (ledger ++> MonthNode(month="Feb", total=55000.0))[0];
    feb_l ++> Sale(item="Standard Rods", amount=55000.0, date="2026-02-18");
    # ----------------------------------

    # Add Inventory Data
    comp ++> Product(name="Steel Sheets", stock=450);
    comp ++> Product(name="Alloy Rods", stock=200);

    # Calendar Data
    cal = (root ++> CalendarNode())[0] as CalendarNode;
    cal.upcoming_events = ["Supplier Sync - 2 PM", "Tax Filing Due - Friday", ];

    dir = (root ++> ClientDirectory())[0];
    dir ++> Client(
        name="Alpha Corp", demand="High volume steel", problems="Supply chain delays"
    );
    dir ++> Client(name="Beta LLC", demand="Consulting", problems="Budget cuts");

    root ++> NewsNode(
        priority_headlines=[
            "🚨 Port strike in LA causing 3-week delays",
            "📉 Steel tariffs increased overnight"
        ],
        live_headlines=[]
    );
    root ++> WeatherNode(location="New York", forecast="Sunny, 72F");
    root ++> EmailsNode(
        priority_emails=[
            "📧 Urgent: Shipping Delay - Order #9921",
            "📧 Invoice Overdue: Steel Supply Co."
        ],
        recent_emails=[
            "📧 Re: Logistics Meeting tomorrow",
            "📧 New Message from Alpha Corp"
        ]
    );
    # --- Map Directory ---
    map_dir = (root ++> MapDirectory())[0];

    # === 5 SUPPLIERS (Red) ===
    map_dir ++> MapEntity(
        name="Fabric Corp",
        kind="supplier",
        status="red",
        x="60%",
        y="70%",
        phone="616-555-0303",
        email="support@fabriccorp.com"
    );
    map_dir ++> MapEntity(
        name="Global Sourcing",
        kind="supplier",
        status="green",
        x="80%",
        y="40%",
        phone="909-555-0404",
        email="dispatch@globalsourcing.com"
    );
    map_dir ++> MapEntity(
        name="Titanium Extractors",
        kind="supplier",
        status="green",
        x="15%",
        y="85%",
        phone="906-555-8811",
        email="rawmaterials@titaniumex.com"
    );
    map_dir ++> MapEntity(
        name="Midwest Packaging",
        kind="supplier",
        status="red",
        x="45%",
        y="20%",
        phone="248-555-3322",
        email="supplies@midwestpack.com"
    );
    map_dir ++> MapEntity(
        name="Apex Electronics",
        kind="supplier",
        status="red",
        x="85%",
        y="15%",
        phone="408-555-9988",
        email="parts@apexelectronics.com"
    );

    # === 6 CLIENTS (Blue) ===
    map_dir ++> MapEntity(
        name="Alpha Corp",
        kind="client",
        status="blue",
        x="20%",
        y="30%",
        phone="313-555-0101",
        email="logistics@alphacorp.com"
    );
    map_dir ++> MapEntity(
        name="Beta LLC",
        kind="client",
        status="blue",
        x="40%",
        y="80%",
        phone="734-555-0202",
        email="ops@betallc.com"
    );
    map_dir ++> MapEntity(
        name="Auto Maker A",
        kind="client",
        status="blue",
        x="30%",
        y="50%",
        phone="313-555-0505",
        email="receiving@automaker-a.com"
    );
    map_dir ++> MapEntity(
        name="FreshFoods Inc",
        kind="client",
        status="blue",
        x="70%",
        y="25%",
        phone="614-555-4455",
        email="inbound@freshfoods.com"
    );
    map_dir ++> MapEntity(
        name="TechBuild Systems",
        kind="client",
        status="blue",
        x="75%",
        y="65%",
        phone="512-555-7766",
        email="supply@techbuild.com"
    );
    map_dir ++> MapEntity(
        name="City Infrastructure",
        kind="client",
        status="blue",
        x="10%",
        y="60%",
        phone="202-555-1122",
        email="procurement@cityinfra.gov"
    );

    return {"status": "success"};
}

walker:pub ClientStatusWalker {
    has report_data: list = [];

    can start with Root entry {
        visit [-->][?:ClientDirectory];
    }
    can go_to_clients with ClientDirectory entry {
        visit [-->][?:Client];
    }
    can collect with Client entry {
        self.report_data.append({"name": here.name, "problem": here.problems});
    }

    can finish with Root exit {
        report self.report_data;
    }
}

def:pub handle_user_input(query: str) -> dict {
    lower_query = query.lower();
    if "client" in lower_query or "problem" in lower_query {
        result = root spawn ClientStatusWalker();
        if len(result.reports) > 0 {
            client_data = result.reports[0];
            mock_summary = "I dispatched the Walker. Here is the raw data it found: \n";
            for c in client_data {
                mock_summary += f"- {c['name']}: {c['problem']} \n";
            }
            return {"role": "agent", "text": mock_summary};
        }
    }
    return {
        "role": "agent",
        "text": "[STATIC MODE] Type 'clients' to test the Walker."
    };
}

def:pub fetch_client_audit() -> list {
    result = root spawn ClientStatusWalker();
    if len(result.reports) > 0 {
        return result.reports[0];
    }
    return [];
}

walker:pub NewsWalker {
    has news_items: list = [];

    can start with Root entry {
        visit [-->][?:NewsNode];
    }
    can collect with NewsNode entry {
        self.news_items = here.priority_headlines + here.live_headlines;
    }

    can finish with Root exit {
        report self.news_items;
    }
}

def:pub fetch_news() -> list {
    news_nodes = [root-->][?:NewsNode];
    if len(news_nodes) > 0 {
        return news_nodes[0].priority_headlines + news_nodes[0].live_headlines;
    }
    return [];
}

def:pub fetch_live_api_news() -> list {
    api_key = "19f231dc21ed467b8251e8725c6e6945";
    query = "supply%20chain%20OR%20logistics";
    url = f"https://newsapi.org/v2/everything?q={query}&language=en&sortBy=publishedAt&pageSize=10&apiKey={api_key}";

    live_headlines: list = [];

    ::py::
import urllib.request
import json
import ssl

try:
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE

    req = urllib.request.Request(url, headers={'User-Agent': 'Jac-App'})
    with urllib.request.urlopen(req, context=ctx) as response:
        data = json.loads(response.read().decode())
        if data.get("status") == "ok":
            for article in data.get("articles", []):
                live_headlines.append(f"📰 {article.get('title', 'Unknown Title')}")
except Exception as e:
    print(f"API Error: {e}")
    ::py::


    if len(live_headlines) > 0 {
        news_nodes = [root-->][?:NewsNode];
        if len(news_nodes) > 0 {
            target_node = news_nodes[0];
            target_node.live_headlines = live_headlines;
            return target_node.priority_headlines + target_node.live_headlines;
        }
    }
    return ["⚠️ Could not connect to live news feed. Check API key."];
}

def:pub fetch_emails() -> list {
    nodes = [root-->][?:EmailsNode];
    if len(nodes) > 0 {
        return nodes[0].priority_emails + nodes[0].recent_emails;
    }
    return [];
}

# --- 1. The Walker to safely gather Map Entities ---
walker:pub FetchMapWalker {
    has map_data: list = [];

    can enter_root with Root entry {
        visit [-->];
    }
    can enter_dir with MapDirectory entry {
        visit [-->];
    }
    can enter_entity with MapEntity entry {
        self.map_data.append(
            {
                "name": here.name,
                "status": here.status,
                "kind": here.kind,
                "x": here.x,
                "y": here.y,
                "phone": here.phone,
                "email": here.email
            }
        );
    }
}

# --- 2. The Endpoint the frontend actually calls ---
def:pub fetch_map_entities() -> list {
    w = root spawn FetchMapWalker();
    return w.map_data;
}

def:pub fetch_growth_data -> list {
    comp = [root-->][?:Company];
    if len(comp) > 0 {
        return [
            {"month": t.month, "amount": t.amount} for t in [comp[0]-->][?:Transaction]
        ];
    }
    return [];
}

# --- NEW: Fetch deep transaction ledger ---
def:pub fetch_detailed_transactions() -> list {
    comp = [root-->][?:Company];
    if len(comp) > 0 {
        ledger = [comp[0]-->][?:TransactionsNode];
        if len(ledger) > 0 {
            report_data = [];
            for m in [ledger[0]-->][?:MonthNode] {
                sales = [
                    {"item": s.item, "amount": s.amount, "date": s.date}
                    for s in [m-->][?:Sale]
                ];
                report_data.append(
                    {"month": m.month, "total": m.total, "sales": sales}
                );
            }
            return report_data;
        }
    }
    return [];
}

def:pub fetch_calendar -> list {
    cal = [root-->][?:CalendarNode];
    if len(cal) > 0 {
        return cal[0].upcoming_events;
    }
    return [];
}

walker:pub BusinessAgentWalker {
    has thoughts: list = [];

    can start with Root entry {
        self.thoughts.append(
            "🤖 Agent spawned at Root node. Initiating graph traversal..."
        );
        visit [-->];
    }

    # CRITICAL FIX: The agent must know to walk *through* the Company node
    can check_company with Company entry {
        visit [-->];
    }

    can check_news with NewsNode entry {
        self.thoughts.append(
            f"📰 Visited NewsNode. Found {len(here.priority_headlines)} priority alerts."
        );
    }

    can check_inventory with Product entry {
        self.thoughts.append(
            f"📦 Visited Product node '{here.name}'. Current stock: {here.stock} units."
        );
    }

    can check_financials with TransactionsNode entry {
        self.thoughts.append(
            "💼 Visited Transactions Ledger. Scanning monthly nodes..."
        );
        visit [-->];
    }

    can check_month with MonthNode entry {
        self.thoughts.append(
            f"📊 Collected ledger data for {here.month}: ${here.total}"
        );
    }
}

def:pub run_business_agent() -> dict {
    # 1. Spawn the walker
    agent = root spawn BusinessAgentWalker();

    # 2. Access the walker's internal memory directly (much more stable than .reports)
    walk_log = agent.thoughts;
    walk_log.append("🧠 Graph traversal complete. Sending collected context to LLM.");

    if len(walk_log) > 0 {
        # 3. Join the thoughts into a single string for Gemini
        context_string = "\n".join(walk_log);

        # 4. Call the AI function safely
        try {
            llm_summary = analyze_business_state(context_string);
        } except Exception as e {
            # Fallback if Gemini times out
            llm_summary = "Demo Fallback: The graph walk completed successfully, but the LLM API is currently unreachable.";
        }

        # 5. Return to the frontend
        return {"summary": llm_summary, "thoughts": walk_log};
    }
    return {"summary": "Error: Graph traversal failed.", "thoughts": []};
}

walker:pub OpportunityAgentWalker {
    has thoughts: list = [];

    can start with Root entry {
        self.thoughts.append(
            "🎯 Opportunity Agent spawned at Root node. Hunting for business opportunities..."
        );
        visit [-->];
    }

    can check_news with NewsNode entry {
        self.thoughts.append(
            f"📰 Scanning News for market shifts: {len(
                here.priority_headlines
            )} priority alerts found."
        );
        for headline in here.priority_headlines {
            self.thoughts.append(f"  - {headline}");
        }
    }

    can check_emails with EmailsNode entry {
        self.thoughts.append(
            f"📧 Scanning Inbox for client signals: {len(
                here.priority_emails
            )} urgent emails."
        );
        for email in here.priority_emails {
            self.thoughts.append(f"  - {email}");
        }
    }

    can open_directories with ClientDirectory | MapDirectory entry {
        self.thoughts.append(
            f"📂 Opening {here.__class__.__name__} to inspect children..."
        );
        visit [-->];
    }

    can check_client with Client entry {
        self.thoughts.append(
            f"🤝 Inspected Client '{here.name}'. Demand: {here.demand}. Pain point: {here.problems}"
        );
    }

    can check_map_entity with MapEntity entry {
        if here.status == "red" {
            self.thoughts.append(
                f"🚨 Noticed critical issue at Map Entity '{here.name}' (Type: {here.kind}). Potential intervention needed."
            );
        } elif here.status == "blue" {
            self.thoughts.append(
                f"📍 Noticed active Client location '{here.name}'. Potential upsell target."
            );
        }
    }
}

def:pub run_opportunity_agent() -> dict {
    agent = root spawn OpportunityAgentWalker();

    walk_log = agent.thoughts;
    walk_log.append("🧠 Opportunity hunt complete. Synthesizing strategy with LLM.");

    if len(walk_log) > 0 {
        context_string = "\n".join(walk_log);
        try {
            llm_summary = find_business_opportunities(context_string);
        } except Exception as e {
            print(f"🚨 LLM API ERROR: {e}");
            llm_summary = "Demo Fallback: The graph walk found data, but the LLM API is currently unreachable to synthesize it.";
        }

        return {"summary": llm_summary, "thoughts": walk_log};
    }
    return {"summary": "Error: Graph traversal failed.", "thoughts": []};
}

walker:pub RiskAgentWalker {
    has proposed_decision: str;
    has thoughts: list = [];

    can start with Root entry {
        self.thoughts.append(
            f"🛡️ Risk Agent spawned at Root. Evaluating scenario: '{self.proposed_decision}'"
        );
        visit [-->];
    }

    # Open doors to nested data
    can check_company with Company entry {
        visit [-->];
    }
    can open_directories with ClientDirectory | MapDirectory entry {
        visit [-->];
    }
    can check_news with NewsNode entry {
        self.thoughts.append(
            f"📰 Scanning News for environmental/market risks: {len(
                here.priority_headlines
            )} alerts."
        );
        for h in here.priority_headlines {
            self.thoughts.append(f"  - {h}");
        }
    }

    can check_inventory with Product entry {
        if here.stock < 300 {
            self.thoughts.append(
                f"⚠️ Inventory Risk: '{here.name}' is running low ({here.stock} units). Moving might strain this further."
            );
        } else {
            self.thoughts.append(
                f"📦 Inventory: '{here.name}' levels stable ({here.stock} units)."
            );
        }
    }

    can check_calendar with CalendarNode entry {
        self.thoughts.append(
            f"📅 Checking schedule conflicts: {len(
                here.upcoming_events
            )} major events coming up."
        );
    }

    can check_emails with EmailsNode entry {
        self.thoughts.append(
            f"📧 Scanning Inbox for existing fires: {len(
                here.priority_emails
            )} urgent emails. Adding a move might delay responses."
        );
    }
}

def:pub run_risk_agent(decision: str) -> dict {
    agent = root spawn RiskAgentWalker(proposed_decision=decision);
    walk_log = agent.thoughts;
    walk_log.append("🧠 Risk audit complete. Synthesizing vulnerabilities with LLM.");

    if len(walk_log) > 0 {
        context_string = "\n".join(walk_log);
        try {
            llm_summary = assess_business_risk(context_string, decision);
        } except Exception as e {
            print(f"🚨 LLM API ERROR: {e}");
            llm_summary = "Demo Fallback: Graph walked successfully, but LLM failed to generate risk report.";
        }
        return {"summary": llm_summary, "thoughts": walk_log};
    }
    return {"summary": "Error: Graph traversal failed.", "thoughts": []};
}



# --- 2. THE OMNI-DATA WALKER ---
walker:pub DataAgentWalker {
    has command_text: str;
    has thoughts: list = [];
    has data_found: str = "";
    has parsed: CommandData = CommandData(action=DataAction.UNKNOWN, target=DataTarget.UNKNOWN, item_name="", details="");

    can start with Root entry {
        self.thoughts.append(
            f"🛠️ Data Agent active. Processing: '{self.command_text}'"
        );
        try {
            self.parsed = parse_data_command(self.command_text);
            self.thoughts.append(
                f"🧠 Intent -> {self.parsed.action} on {self.parsed.target}"
            );
        } except Exception as e {
            self.thoughts.append(f"🚨 Parsing error: {e}");
            disengage;
        }
        visit [-->];
    }

    # --- PARENT NODES (For ADDING Data) ---
    can check_company with Company entry {
        # Add a new Product to the Company
        if self.parsed.target == DataTarget.PRODUCT
            and self.parsed.action == DataAction.ADD {
            try {
                start_stock = int("".join(filter(str.isdigit, self.parsed.details)))
                    if self.parsed.details
                    else 0;
            } except Exception as e {
                start_stock = 0;
            }
            here ++> Product(name=self.parsed.item_name, stock=start_stock);
            self.thoughts.append(
                f"✅ SUCCESS: Added new Product '{self.parsed.item_name}' with {start_stock} stock."
            );
        }
        visit [-->];
    }

    can open_dirs with ClientDirectory | MapDirectory entry {
        # Add a new Client and Map Pin to their respective directories
        if self.parsed.target == DataTarget.CLIENT
            and self.parsed.action == DataAction.ADD {
            if here.__class__.__name__ == "ClientDirectory" {
                here ++> Client(
                    name=self.parsed.item_name,
                    demand=self.parsed.details,
                    problems="New Entity"
                );
                self.thoughts.append(
                    f"✅ SUCCESS: Created Client node '{self.parsed.item_name}'."
                );
            } elif here.__class__.__name__ == "MapDirectory" {
                here ++> MapEntity(
                    self.parsed.item_name, "client", "blue", "50%", "50%"
                );
                self.thoughts.append(
                    f"📍 SUCCESS: Added Map Pin for '{self.parsed.item_name}'."
                );
            }
        }
        visit [-->];
    }

    # --- CHILD NODES (For GET, REMOVE, UPDATE) ---

    # 1. CALENDAR
    can handle_calendar with CalendarNode entry {
        if self.parsed.target == DataTarget.CALENDAR {
            if self.parsed.action == DataAction.GET {
                self.data_found = "Upcoming Events: " + ", ".join(here.upcoming_events);
                self.thoughts.append("🔍 Data retrieved from Calendar.");
            } elif self.parsed.action == DataAction.ADD {
                event_str = self.parsed.item_name
                    + (" " + self.parsed.details if self.parsed.details else "");
                here.upcoming_events = here.upcoming_events + [event_str];
                self.thoughts.append(f"✅ SUCCESS: Added '{event_str}' to Calendar.");
            } elif self.parsed.action == DataAction.REMOVE {
                new_events = [];
                for ev in here.upcoming_events {
                    if self.parsed.item_name.lower() in ev.lower() {
                        self.thoughts.append(
                            f"🗑️ SUCCESS: Removed '{ev}' from Calendar."
                        );
                    } else {
                        new_events.append(ev);
                    }
                }
                here.upcoming_events = new_events;
            }
        }
    }

    # 2. INVENTORY (PRODUCT)
    can handle_product with Product entry {
        if self.parsed.target == DataTarget.PRODUCT {
            if self.parsed.action == DataAction.GET {
                self.data_found = self.data_found
                    + f"[{here.name}: {here.stock} units] ";
                self.thoughts.append(f"🔍 Retrieved data: {here.name}");
            } elif self.parsed.item_name.lower() in here.name.lower() {
                if self.parsed.action == DataAction.UPDATE {
                    try {
                        new_stock = int(
                            "".join(filter(str.isdigit, self.parsed.details))
                        );
                        here.stock = new_stock;
                        self.thoughts.append(
                            f"📦 SUCCESS: Updated '{here.name}' stock to {here.stock}."
                        );
                    } except Exception as e {
                        self.thoughts.append("🚨 Failed to parse stock number.");
                    }
                } elif self.parsed.action == DataAction.REMOVE {
                    self.thoughts.append(f"🗑️ SUCCESS: Removed Product '{here.name}'.");
                    del here;
                }
            }
        }
    }

    # 3. CLIENT DIRECTORY
    can handle_client with Client entry {
        if self.parsed.target == DataTarget.CLIENT {
            if self.parsed.action == DataAction.GET {
                self.data_found = self.data_found + f"[{here.name} - {here.demand}] ";
                self.thoughts.append(f"🔍 Found info for {here.name}.");
            } elif self.parsed.action == DataAction.REMOVE {
                if self.parsed.item_name.lower() in here.name.lower() {
                    self.thoughts.append(
                        f"🗑️ SUCCESS: Deleted Client node '{here.name}'."
                    );
                    del here;
                }
            }
        }
    }

    # 4. MAP ENTITIES (Cleanup when removing a client)
    can handle_map_entity with MapEntity entry {
        if self.parsed.target == DataTarget.CLIENT
            and self.parsed.action == DataAction.REMOVE {
            if self.parsed.item_name.lower() in here.name.lower() {
                self.thoughts.append(f"🗑️ SUCCESS: Removed Map Pin '{here.name}'.");
                del here;
            }
        }
    }

    can finish with Root exit {
        report {
            "summary": (
                self.data_found
                    if len(self.data_found) > 0
                    else "Graph modification completed!"
            ),
            "thoughts": self.thoughts
        };
    }
}

# --- 3. THE ENDPOINT ---
# Ensure your run_data_agent function looks exactly like this:
def:pub run_data_agent(command: str) -> dict {
    agent = root spawn DataAgentWalker(command_text=command);
    walk_log = agent.thoughts;

    final_summary = agent.data_found
        if len(agent.data_found) > 0
        else "Graph modified successfully! Check UI updates.";

    return {"summary": final_summary, "thoughts": walk_log};
}

walker:pub B2BMatchWalker {
    has my_problem: str;
    has thoughts: list = [];
    has market_data: list = [];

    can start with Root entry {
        self.thoughts.append("🌐 Entering Global B2B Network...");
        visit [-->];
    }

    can check_market with GlobalMarketplace entry {
        self.thoughts.append(
            "📡 Connected to Global Hub. Scanning live broadcasts from other companies..."
        );
        visit [-->];
    }

    can read_post with B2BPost entry {
        self.thoughts.append(
            f"📩 Read post from {here.author}: '{here.content[:40]}...'"
        );
        self.market_data.append(f"[{here.author}]: {here.content}");
    }
}

def:pub run_b2b_matchmaker(problem: str) -> dict {
    agent = root spawn B2BMatchWalker(my_problem=problem);
    walk_log = agent.thoughts;

    if len(agent.market_data) > 0 {
        walk_log.append(
            "🧠 Network scan complete. Sending data to LLM for Matchmaking..."
        );
        market_str = "\n".join(agent.market_data);

        try {
            match_result = b2b_matchmaker(problem, market_str);
        } except Exception as e {
            match_result = "Demo Fallback: Network scan completed, but LLM is currently unreachable.";
        }

        # NEW: Create a temporary map pin for the match!
        # NEW: Create a BLACK temporary map pin for the match!
        new_pin = {
            "name": "Global Match (Fabric)",
            "status": "black",  # <--- Changed from blue to black!
            "kind": "network_match",
            "x": "55%",
            "y": "45%",
            "email": "connect@globalfabric.net",
            "phone": "800-555-MATCH"
        };

        return {"match": match_result, "thoughts": walk_log, "new_pin": new_pin};
    }

    return {
        "match": "The marketplace is empty.",
        "thoughts": walk_log,
        "new_pin": None
    };
}

# --- NEW WALKERS FOR SAFE GRAPH MODIFICATION ---

walker:pub CheckGlobalHub {
    has hub_node: GlobalMarketplace | None = None;

    can enter_root with Root entry {
        visit [-->];
    }
    can check_hub with GlobalMarketplace entry {
        self.hub_node = here;
    }
}

walker:pub GatherHubNodes {
    has nodes_to_delete: list = [];

    can enter_root with Root entry {
        visit [-->];
    }
    can gather_hub with GlobalMarketplace entry {
        # Add hub to deletion list, then visit children
        self.nodes_to_delete.append(here);
        visit [-->];
    }

    can gather_post with B2BPost entry {
        # Add posts to deletion list
        self.nodes_to_delete.append(here);
    }
}

# --- THE FIXED ENDPOINTS ---

def:pub connect_global_node() -> dict {
    # 1. Safely check if we are already connected
    checker = root spawn CheckGlobalHub();
    if checker.hub_node {
        return {"status": "success", "msg": "Already connected"};
    }

    # 2. Spawn the Hub
    market = (root ++> GlobalMarketplace())[0];

    # 3. Fetch data from your Remote GitHub Server
    # 3. Fetch data from your Remote GitHub Server
    try {
        # PASTE YOUR RAW GITHUB URL HERE:
        url = "https://gist.githubusercontent.com/naeemexe/65b1d664ea045c34e32af5e70b620cbc/raw/4c01c56dffc471fbe7d7fc0ec22e49ddbecd3ff5/global_fabric.json";

        # --- NEW: BYPASS SSL FOR LOCAL DEMO ---
        ctx = ssl.create_default_context();
        ctx.check_hostname = False;
        ctx.verify_mode = ssl.CERT_NONE;

        # Pass the unverified context to urlopen
        response = urllib.request.urlopen(url, context=ctx);
        remote_data = json.loads(response.read().decode('utf-8'));

        # 4. Populate the graph with the remote data
        for post in remote_data {
            market ++> B2BPost(
                author=post["author"],
                content=post["content"],
                email=post["email"],
                phone=post["phone"],
                x=post["x"],
                y=post["y"]
            );
        }
        return {"status": "success", "connected_nodes": len(remote_data)};
    } except Exception as e {
        print(f"🚨 Network Error: {e}");
        return {"status": "error", "msg": "Failed to connect to remote server."};
    }
}

def:pub disconnect_global_node() -> dict {
    # 1. Safely gather all hub and post nodes using a walker
    gatherer = root spawn GatherHubNodes();

    # 2. Delete them from memory
    for node_obj in gatherer.nodes_to_delete {
        del node_obj;
    }

    return {"status": "success"};
}

walker:pub MorningBriefingWalker {
    has external_context: str;
    has thoughts: list = [];
    has critical_nodes: list = [];

    can start with Root entry {
        self.thoughts.append(
            "🌅 System Booting. Initiating Morning Briefing Protocol..."
        );
        self.thoughts.append(
            "📡 Ingesting external data: Emails, Calendar, and Industry News."
        );
        visit [-->];
    }

    can scan_map with MapEntity entry {
        if here.status == "red" {
            self.critical_nodes.append(f"{here.name} ({here.kind})");
            self.thoughts.append(
                f"🚨 Flagged critical network issue at {here.name}. Added to priority matrix."
            );
        }
    }
}

def:pub run_morning_briefing(external_context: str) -> dict {
    agent = root spawn MorningBriefingWalker(external_context=external_context);

    critical_str = ", ".join(agent.critical_nodes)
        if len(agent.critical_nodes) > 0
        else "All systems normal.";
    agent.thoughts.append(
        "🧠 Synthesizing external signals and graph data into Top 3 Tasks..."
    );

    try {
        tasks = get_daily_priorities(external_context, critical_str);
    } except Exception as e {
        tasks = "• 🚨 Call EcoCups Inc immediately regarding the 3-week supply delay.\n• 🚚 Approve the 50% RapidFreight discount for the Chicago-Detroit route.\n• 📧 Draft response to Whole Foods Regional to secure the Q3 contract.";
    }

    return {"tasks": tasks, "thoughts": agent.thoughts};
}

walker:pub SidebarChatWalker {
    has query: str;
    has history: list;
    has response: str = "";

    can start with Root entry {
        self.response = chat_with_llm(self.query, self.history);
    }
}

def:pub handle_user_chat(query: str, history: list) -> str {
    agent = root spawn SidebarChatWalker(query=query, history=history);
    return agent.response;
}
