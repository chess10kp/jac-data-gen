# nat-l4-panel-load
New load.jac + edit of existing reports.jac walker (format change, keep semantics). Mixed edge directions (Feeds out, PluggedInto in).
Alternative: two-hop visit to outlets, incoming untyped filters, integer threshold comparison.
- Reference first used `visit :0: [here ->:Feeds:->]` (depth-first insert per jac-walker-patterns guide) with a walker-held current-breaker label; on 0.37.25 CI the inventory came out mislabeled, so the reference now reads outlets inside the Breaker ability. Root cause of the :0: ordering not isolated.
- jac 0.36.1 port: alt compares in watts: `round()` result typed as generic _T at 0.36.1 (E1010 on *).
