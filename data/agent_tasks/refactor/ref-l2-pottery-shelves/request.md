The shelf tracker in `shelves.jac` works, but it's basically a Python dict-of-dicts stuffed into a single `Studio` node, and every function digs through nested dictionaries. I'd like it modelled properly as a graph: shelves and pieces as their own node types, pieces hanging off the shelf they sit on, and the lookups done with edge filters instead of scanning dicts (and no `isinstance` hunting for the studio node either).

The six public functions have to keep their names, signatures and results — the front desk tool calls them.
