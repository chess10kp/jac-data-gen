walker dispatch_agents {
    has crisis_type: any;

    can initialize_response with Root entry {
        report "Commander Agent Activated";
        report "Medical Agent Activated";
        report "Rescue Agent Activated";
        report "Logistics Agent Activated";
    }
}
