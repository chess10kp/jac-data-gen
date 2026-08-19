with entry {
    root ++> Ticket(title="App crash", description="App crashes on startup");
    root ++> Ticket(title="Typo", description="Small typo on homepage");
    root ++> Ticket(title="Data loss", description="Customer data was deleted");

    result = root spawn PrioritizeTickets();

    for ticket in result.reports {
        print(f"[{ticket.priority}] {ticket.title}");
    }
}
