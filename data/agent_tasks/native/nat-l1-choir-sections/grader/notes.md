# nat-l1-choir-sections
Enum iteration (for p in Part), part.name keys, all four keys present, eligibility = active and rehearsals>=2, short in declaration order with strict <.
Alternative: node-side ability appending to visitor, explicit enum list at exit.
- jac 0.36.1 port: alt iterates `for p in Part` (0.36.1 checker loses `.name` on a list literal of enum members, E1099).
