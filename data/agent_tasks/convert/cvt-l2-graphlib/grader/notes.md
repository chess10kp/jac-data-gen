# cvt-l2-graphlib
Source: CPython v3.12.7 Lib/graphlib.py (PSF-2.0). Hidden tests: upstream test_graphlib.py ported
(group ordering via get_ready/done, static_order, cycles incl. args[1] content, error messages),
minus the TypeError-for-unhashable and PYTHONHASHSEED subprocess tests (the latter replaced by a fixed
expected order for string nodes, value taken from CPython). Extra: progress after CycleError,
"already marked done". Quirks: `node` and `graph` are Jac keywords -> renamed param/field (`deps`);
lambdas in tests need `-> any` when the body returns a value (E1002 with `-> None`).
Negatives: successor never becomes ready, cycle never raised, ready list not cleared, predecessor
count +1 instead of +len, is_active ignores pending ready nodes.
