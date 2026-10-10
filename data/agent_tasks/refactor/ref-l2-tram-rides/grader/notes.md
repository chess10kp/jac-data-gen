# ref-l2-tram-rides
Smell: the graph model is already idiomatic (Stop nodes, typed Track edge with line/minutes) but riding a line is a while-loop that hops `cur = [cur ->:Track:line == ln:->][0]` by hand and packs its results into a dict[str, any] that three wrappers unpack.
Target: one Ride walker spawned on the start stop: appends the stop, adds the minutes of the outgoing hop on its line (edge objects), `visit`s the next stop on that line, and `disengage`s (flagging the loop) when it reaches a stop it has already passed. The three public functions spawn it and read its fields.
Idiom targets: >=1 walker, >=1 visit, >=1 spawn (starter already has nodes/edges/filters; this task is only the traversal).
Semantics: the closing hop of a loop is counted in ride_minutes; ride() lists each stop once; unknown start -> [], 0, False.
