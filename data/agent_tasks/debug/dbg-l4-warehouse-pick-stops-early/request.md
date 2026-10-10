Two pick-run issues reported by the floor team:

1. Orders come back short even though stock exists further down the aisle chain. Example: order bolt×10, nut×3; aisle 1 has 6 bolts and 1 nut, aisle 2 has 5 nuts, aisle 3 has 100 bolts. The run picked aisle 1 and aisle 2 and then stopped, reporting 4 bolts short.
2. The order dict the sales system passes into `PickRun(order=...)` comes back modified (quantities reduced to 0), which breaks their invoicing. The walker must not change the caller's order.

`jac run main.jac` should print "picked 5 lines, short 4 units" for the demo warehouse.
