"""frontend.impl.jac - Implementations for Sidebar Agents"""

impl app.initialize_dashboard {
    # 1. Boot up the local graph
    await setup_graph("My Awesome Startup");
    chat_history = [{"role": "agent", "text": "Dashboard online. Good morning."}];
    
    # 2. Fetch disparate data sources concurrently
    suggestions = await fetch_news();
    emails = await fetch_emails();
    map_entities = await fetch_map_entities();
    growth_data = await fetch_growth_data();
    calendar_events = await fetch_calendar();
    detailed_tx_data = await fetch_detailed_transactions();
    
    # 3. TRIGGER AUTORUN MORNING BRIEFING
    loading_boot = True;
    
    # Combine the mocked strings so the AI has context
    context_string = f"News Data: {suggestions} | Urgent Emails: {emails} | Today's Calendar: {calendar_events}";
    
    # Fire the bootup agent!
    boot_res = await run_morning_briefing(context_string);
    
    daily_tasks = boot_res["tasks"];
    boot_thoughts = boot_res["thoughts"];
    loading_boot = False;
    
    # Optional: Log it to history automatically
    agent_history = [{"type": "🌅 Morning Briefing", "summary": daily_tasks, "thoughts": boot_thoughts}] + agent_history;
}

impl app.handle_ask_agent {
    if not chat_input.strip() { return; }
    
    # 1. Add user message to UI immediately
    new_msg = {"role": "user", "text": chat_input};
    chat_history = chat_history + [new_msg];
    
    # 2. Clear input and show loading
    current_query = chat_input;
    chat_input = "";
    loading_agent = True;
    
    # 3. Call the backend
    try {
        # We pass the history so the LLM remembers previous messages
        reply_text = await handle_user_chat(current_query, chat_history);
        
        # 4. Add agent response to UI
        chat_history = chat_history + [{"role": "agent", "text": reply_text}];
    } except Exception as e {
        chat_history = chat_history + [{"role": "agent", "text": "⚠️ Connectivity issue. Check your API key."}];
    }
    
    loading_agent = False;
}

impl app.handle_keypress(e: KeyboardEvent) {
    if e.key == "Enter" { handle_ask_agent(); }
}

impl app.run_manual_audit {
    loading_agent = True;
    client_data = await fetch_client_audit();
    new_suggestions = [];
    for client in client_data { new_suggestions.append(f"- {client['name']} Warning: {client['problem']}"); }
    suggestions = new_suggestions;
    loading_agent = False;
}

impl app.run_live_news_fetch {
    fetching_news = True;
    live_data = await fetch_live_api_news();
    if len(live_data) > 0 { suggestions = live_data; }
    fetching_news = False;
}

# --- AGENT LOGIC (UPDATES ACTIVE MONITOR AND SAVES HISTORY) ---

impl app.trigger_agent_analysis {
    running_analyst = True;
    result = await run_business_agent();
    
    latest_run_type = "📊 Analyst";
    latest_run_summary = result["summary"];
    latest_run_thoughts = result["thoughts"];
    
    agent_history = [{"type": latest_run_type, "summary": result["summary"], "thoughts": result["thoughts"]}] + agent_history;
    running_analyst = False;
}

impl app.trigger_opp_analysis {
    running_opp = True;
    result = await run_opportunity_agent();
    
    latest_run_type = "🎯 Strategy";
    latest_run_summary = result["summary"];
    latest_run_thoughts = result["thoughts"];
    
    agent_history = [{"type": latest_run_type, "summary": result["summary"], "thoughts": result["thoughts"]}] + agent_history;
    running_opp = False;
}

impl app.trigger_risk_analysis {
    if not risk_input.strip() { return; }
    running_risk = True;
    
    result = await run_risk_agent(risk_input.strip());
    
    latest_run_type = f"🛡️ Risk ({risk_input.strip()})";
    latest_run_summary = result["summary"];
    latest_run_thoughts = result["thoughts"];
    
    agent_history = [{"type": latest_run_type, "summary": result["summary"], "thoughts": result["thoughts"]}] + agent_history;
    running_risk = False;
    risk_input = "";
}

impl app.trigger_data_analysis {
    if not data_input.strip() { return; }
    running_data = True;
    
    result = await run_data_agent(data_input.strip());
    
    map_entities = await fetch_map_entities();
    calendar_events = await fetch_calendar();
    growth_data = await fetch_growth_data();
    detailed_tx_data = await fetch_detailed_transactions();
    
    latest_run_type = f"🛠️ Data ({data_input.strip()})";
    latest_run_summary = result["summary"];
    latest_run_thoughts = result["thoughts"];
    
    agent_history = [{"type": latest_run_type, "summary": result["summary"], "thoughts": result["thoughts"]}] + agent_history;
    running_data = False;
    data_input = "";
}

# --- NEW: GLOBAL FABRIC LOGIC ---

impl app.trigger_add_problem {
    if not problem_input.strip() { return; }
    my_problems = my_problems + [problem_input.strip()];
    problem_input = "";
}

impl app.handle_problem_keypress(e: KeyboardEvent) {
    if e.key == "Enter" { trigger_add_problem(); }
}

impl app.trigger_b2b_match {
    if len(my_problems) == 0 { return; }
    running_b2b = True;
    
    combined_problems = " | ".join(my_problems);
    result = await run_b2b_matchmaker(combined_problems);
    
    latest_run_type = "🌐 GlobalFabric Match";
    latest_run_summary = result["match"];
    latest_run_thoughts = result["thoughts"];
    
    # CRITICAL FIX: Using {} instead of : for Jac syntax
    if result.get("new_pin") {
        map_entities = map_entities + [result["new_pin"]];
        # Auto-select it so the user sees the contact info immediately
        selected_name = str(result["new_pin"]["name"]);
        selected_node = result["new_pin"];
    }
    
    agent_history = [{"type": latest_run_type, "summary": result["match"], "thoughts": result["thoughts"]}] + agent_history;
    
    running_b2b = False;
}

impl app.toggle_global_fabric {
    if global_fabric_on {
        # Turn OFF: Disconnect and wipe the data
        connecting_fabric = True;
        await disconnect_global_node();
        
        global_fabric_on = False;
        connecting_fabric = False;
        latest_run_summary = ""; # Clear any match text from the screen
    } else {
        # Turn ON: Reach out to GitHub and build the graph
        connecting_fabric = True;
        await connect_global_node();
        
        global_fabric_on = True;
        connecting_fabric = False;
    }
}