enum Priority { LOW, MEDIUM, HIGH }

node Ticket {
    has title: str;
    has description: str;
    has priority: Priority = Priority.MEDIUM;
}

def analyze_priority(title: str, description: str) -> Priority by llm();

walker PrioritizeTickets {
    can with Root entry { visit [-->]; }

    can prioritize with Ticket entry {
        here.priority = analyze_priority(here.title, here.description);
        report here;
        visit [-->];
    }
}
