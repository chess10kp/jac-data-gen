rsvp.jac refactor, please.

Right now it's one `RsvpBook` node (found via isinstance over root) holding a dict of event dicts, each with a nested answers dict, plus a separate key->display-name dict. Answers are "yes"/"no"/"maybe" strings.

Make it graph-native: events and guests as nodes, each answer a typed edge from guest to event carrying the answer and the plus-ones. Answer becomes an enum (callers still send the strings). Use walkers for the work: one that records/replaces an answer from root (capacity check included), one that rolls up an event (seats taken, who said what), one that builds a guest's agenda. Prefer edge filters/predicates over scanning.

Also split declarations from implementations: `rsvp.jac` holds the enum, nodes, edge, walker declarations and function signatures; all bodies go into `rsvp.impl.jac`.

Nothing changes for callers: same `rsvp` module, same `rsvp`, `set_capacity`, `headcount`, `guests`, `agenda`, `cancel` functions, same arguments, same results and error strings.
