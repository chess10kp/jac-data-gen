# nat-l3-parking-garage
Lowest-number level ordering (levels created out of order), capacity, dup plate across levels, fee ceil-hours with 30-min grace, node deletion, occupancy incl. empty levels. Cross-process run gate.
Alternative: Enter visits levels with an ordering term in the filter ([?:Level, number]) and disengages; Leave deletes via filtered traversal.
- jac 0.36.1 port: alt: ordering term `[?:Level, number]` crashes the 0.36.1 checker -> sorted(); `del <node comprehension>` -> `del c`.
