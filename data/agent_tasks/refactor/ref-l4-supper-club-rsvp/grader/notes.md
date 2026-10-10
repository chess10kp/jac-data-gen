# ref-l4-supper-club-rsvp
Smell: `RsvpBook` bucket node (isinstance scan) with `events: dict[str, dict[str, any]]` (capacity + nested answers dict) and `names: dict[str, str]`; answer strings; all bodies inline.
Target: rsvp.jac = interface (enum Answer; nodes Event{capacity}/Guest{key, display}; edge Rsvp{answer, plus_ones}; walkers Respond / Roster / Agenda; 10 function decls); rsvp.impl.jac = 13 impl blocks.
Idiom targets: node>=2, edge>=1, walker>=3 (request names three), enum>=1, edge_filters>=1, spawns>=3, dict_fields==0, isinstance==0, annex_impls>=8 (6 public functions + 3 abilities).
Behaviour: guest identity = stripped lowercase name, display = latest successful spelling (global across events); a re-answer replaces the edge (`del [edge g ->:Rsvp:-> ev]`); capacity check excludes the guest's own previous yes; a "full" answer leaves the old answer untouched; seats = yes answers + their plus-ones.
Negatives: plus_ones_for_maybe, keeps_old_answer, capacity_counts_self, plus_ones_cap_four, agenda_skips_maybe, cancel_wrong_event.
Quirk: edge predicates compare scalars only (`[g ->:Rsvp:answer == Answer.YES:->]` raises "QPred value ... must be a scalar"), so Agenda reads the edge objects instead.
