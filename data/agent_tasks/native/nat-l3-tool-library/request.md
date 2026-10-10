Our neighbourhood tool library runs on a small Jac graph in `toollib.jac`. Tools and members are nodes on `root`; a loan is a `Lent` edge from a `Member` to a `Tool` carrying the day it is due back. `RegisterTool` already works. I need the other three walkers filled in — each one is spawned on `root` as a separate call (we run them from different scripts on different days, so everything has to live in the graph, not in module variables).

**`Checkout(card, code, day, loan_days=7)`**
- Report exactly one `Receipt`.
- If no tool with that `code` is registered: `Receipt(ok=False, reason="unknown tool")`.
- If the tool is currently lent to anyone: `Receipt(ok=False, reason="already lent")`.
- A member may hold at most 2 tools at a time; a third checkout gets `Receipt(ok=False, reason="limit reached")`.
- Otherwise create the loan (`Lent` edge with `due_day = day + loan_days`) and report `Receipt(ok=True, reason="", due_day=<that day>)`.
- Members are identified by `card`. If the card has never been seen, create the `Member` node on `root` (only once — the same card must always map to the same node).
- Checks happen in that order (unknown tool, then already lent, then limit).

**`Return(code)`**
- Removes the loan for that tool and reports `Receipt(ok=True, reason="")`. If the tool isn't currently lent (or doesn't exist), report `Receipt(ok=False, reason="not lent")`. The member and the tool stay in the graph.

**`OverdueReport(today)`**
- Walk the members and their loans and report, once, a list of `"<card>:<code>"` strings for every loan whose due day is strictly before `today`, ordered by due day and then by tool code.

Keep the existing node/edge/obj declarations and `RegisterTool` as they are.
