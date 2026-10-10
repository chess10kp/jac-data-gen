`kiln_log.jac` has grown into one wall of bodies and it's hard to see the API at a glance. Please split it the Jac way: keep `kiln_log.jac` as the interface (the `Firing` fields plus method and function signatures, no bodies) and move every implementation into a `kiln_log.impl.jac` annex next to it.

Behaviour must not change — same `Firing` constructor and methods, same `firing_line` / `cone_yield` / `worst_batch` signatures and outputs, still imported from `kiln_log`.
