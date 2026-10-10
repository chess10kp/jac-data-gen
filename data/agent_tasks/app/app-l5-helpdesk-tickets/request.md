We need an internal IT help-desk ticket API, written in Jac. This folder is a `jac create --kind service` scaffold — rip out the sample and build the following.

Endpoints (public walkers, `POST /walker/<name>`):

1. `open_ticket` — `subject: str`, `priority: str` (`low` | `normal` | `high`, default `normal`). Tickets get sequential numbers starting at 1. Reports the ticket.
2. `assign_ticket` — `number: int`, `agent: str`. Reports the ticket.
3. `add_comment` — `number: int`, `author: str`, `body: str`. Comments are their own nodes attached to the ticket, kept in order. Reports the ticket.
4. `close_ticket` — `number: int`. A ticket can only be closed once it's assigned. Reports the ticket.
5. `list_tickets` — optional `status: str` (`open` / `closed`; empty = all). Reports one list of tickets ordered high → normal → low priority, then by number.

A reported ticket looks like:

```json
{"number": 3, "subject": "VPN down", "priority": "high", "status": "open",
 "agent": "", "comments": [{"author": "kim", "body": "rebooted"}]}
```

`agent` is `""` until assigned. Any bad request (unknown ticket number, bad priority, empty subject, closing an unassigned or already-closed ticket, commenting on a closed ticket) reports `{"error": "<what went wrong>"}` and changes nothing.

Everything lives on the graph under root. Also add tests and check it starts with `jac start`.
