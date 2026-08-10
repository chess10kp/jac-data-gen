obj Request {
    def perm(resource: str, id: int) -> list[str];
}

"""Apply permissions to a set of milestone tickets as returned by
    get_tickets_for_milestone()."""
def apply_ticket_permissions(env: dict[str, str], req: Request, tickets: list[dict[str, int]]) -> list[dict[str, int]] {
    return [
        t
        for t in tickets
        if 'TICKET_VIEW' in req.perm('ticket', t['id'])
    ];
}