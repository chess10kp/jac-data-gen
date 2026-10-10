Could you rework `course.jac` into proper Jac? Right now `Course` is a plain obj carrying a dict of points and a dict-of-dicts adjacency table, and `reachable` is a hand-rolled BFS queue.

What I have in mind: `Course` becomes a node that owns its controls, each control is its own node, legs are a typed edge carrying the distance, and the reachability / points sweep is done by a walker instead of the while-loop. Legs are one-way, and keep every course's controls separate from any other course.

The public surface stays the same: `Course(name=...)` plus the `add_control`, `add_leg`, `reachable`, `points_from` and `longest_leg_from` methods with the same arguments and return values.
