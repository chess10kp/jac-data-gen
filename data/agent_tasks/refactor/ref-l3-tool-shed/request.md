Our tool shed module (`shed.jac`) grew up as four parallel dictionaries on a `ToolShed` obj — labels, condition, borrower, due day — and every method keeps them in sync by hand. The condition is a bare string too ("ok", "repair", "retired"), which is how we ended up with a "retierd" tool last month.

I'd like this redone the Jac way:

- `ToolShed` becomes a node that owns its own tools and members, so two sheds never see each other's data.
- Tools and members are nodes; a loan is a typed edge from member to tool that carries the due day.
- Tool condition is an enum.
- The overdue report should be a walker that sweeps the shed's tools, not a pile of nested loops.

Please keep the public API exactly as it is: `ToolShed(name=..., limit=...)` and the `register`, `checkout`, `give_back`, `repair`, `retire`, `status`, `on_loan` and `overdue` methods, with the same arguments and the same return values (including the status strings and checkout messages).
