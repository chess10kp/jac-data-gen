enum Priority { LOW, MEDIUM, HIGH }

node Ticket {
    has title: str;
    has description: str;
    has priority: Priority = Priority.MEDIUM;
    has team: str = "unassigned";
}

def analyze_priority(title: str, description: str) -> Priority by llm();

"""Choose the best team to handle this ticket."""
def assign_team(title: str, description: str) -> str by llm();

sem assign_team = "Return one team name: Backend, Frontend, Infrastructure, or Support.";

walker PrioritizeTickets {
    can with Root entry { visit [-->]; }

    can prioritize with Ticket entry {
        here.priority = analyze_priority(here.title, here.description);
        here.team = assign_team(here.title, here.description);
        report here;
        visit [-->];
    }
}
